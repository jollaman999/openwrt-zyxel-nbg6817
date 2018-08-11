/* Copyright (c) 2015 The Linux Foundation. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 *
 */

/**
 * nss_cryptoapi.c
 * 	Interface to communicate Native Linux crypto framework specific data
 * 	to Crypto core specific data
 */

#include <linux/version.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/random.h>
#include <asm/scatterlist.h>
#include <linux/moduleparam.h>
#include <linux/spinlock.h>
#include <asm/cmpxchg.h>
#include <linux/delay.h>
#include <linux/crypto.h>
#include <linux/rtnetlink.h>
#include <linux/debugfs.h>

#include <crypto/ctr.h>
#include <crypto/des.h>
#include <crypto/aes.h>
#include <crypto/sha.h>
#include <crypto/hash.h>
#include <crypto/algapi.h>
#include <crypto/aead.h>
#include <crypto/authenc.h>
#include <crypto/scatterwalk.h>

#include <nss_api_if.h>
#include <nss_crypto_if.h>
#include <nss_cfi_if.h>
#include "nss_cryptoapi.h"

#define nss_cryptoapi_sg_has_frags(s) sg_next(s)

static struct nss_cryptoapi gbl_ctx;

/*
 * nss_cryptoapi_debugs_add_stats()
 * 	Creates debugfs entries for common statistics
 */
static void nss_cryptoapi_debugfs_add_stats(struct dentry *parent, struct nss_cryptoapi_ctx *session_ctx)
{
	debugfs_create_u64("queued", S_IRUGO, parent, &session_ctx->queued);
	debugfs_create_u64("completed", S_IRUGO, parent, &session_ctx->completed);
}

/*
 * nss_cryptoapi_debugfs_add_session()
 * 	Creates per session debugfs entries
 */
void nss_cryptoapi_debugfs_add_session(struct nss_cryptoapi *gbl_ctx, struct nss_cryptoapi_ctx *session_ctx)
{
	char buf[NSS_CRYPTOAPI_DEBUGFS_NAME_SZ];

	if (gbl_ctx->root_dentry == NULL) {
		nss_cfi_err("root directories are not present: unable to add session data\n");
		return;
	}

	memset(buf, 0, NSS_CRYPTOAPI_DEBUGFS_NAME_SZ);
	scnprintf(buf, sizeof(buf), "session%d", session_ctx->sid);

	session_ctx->session_dentry = debugfs_create_dir(buf, gbl_ctx->stats_dentry);
	if (session_ctx->session_dentry == NULL) {
		nss_cfi_err("Unable to create qca-nss-cryptoapi/stats/%s directory in debugfs", buf);
		return;
	}

	/*
	 * create session's stats files
	 */
	nss_cryptoapi_debugfs_add_stats(session_ctx->session_dentry, session_ctx);
}

/*
 * nss_cryptoapi_debugfs_del_session()
 * 	deletes per session debugfs entries
 */
void nss_cryptoapi_debugfs_del_session(struct nss_cryptoapi_ctx *session_ctx)
{
	if (session_ctx->session_dentry == NULL)  {
		nss_cfi_err("Unable to find the directory\n");
		return;
	}

	debugfs_remove_recursive(session_ctx->session_dentry);
}

/*
 * nss_cryptoapi_debugfs_init()
 * 	initiallize the cryptoapi debugfs interface
 */
void nss_cryptoapi_debugfs_init(struct nss_cryptoapi *gbl_ctx)
{
	gbl_ctx->root_dentry = debugfs_create_dir("qca-nss-cryptoapi", NULL);
	if (!gbl_ctx->root_dentry) {

		/*
		 * Non availability of debugfs directory is not a catastrophy
		 * We can still go ahead with other initialization
		 */
		nss_cfi_err("Unable to create directory qca-nss-cryptoapi in debugfs\n");
		return;
	}

	gbl_ctx->stats_dentry = debugfs_create_dir("stats", gbl_ctx->root_dentry);
	if (!gbl_ctx->stats_dentry) {

		/*
		 * Non availability of debugfs directory is not a catastrophy
		 * We can still go ahead with other initialization
		 */
		nss_cfi_err("Unable to create directory qca-nss-cryptoapi/stats in debugfs\n");
		debugfs_remove_recursive(gbl_ctx->root_dentry);
		return;
	}
}

/*
 * nss_cryptoapi_debugfs_exit()
 * 	cleanup the cryptoapi debugfs interface
 */
void nss_cryptoapi_debugfs_exit(struct nss_cryptoapi *gbl_ctx)
{
	if (!gbl_ctx->root_dentry) {
		nss_cfi_err("Unable to find root directory qca-nss-cryptoapi in debugfs\n");
		return;
	}

	debugfs_remove_recursive(gbl_ctx->root_dentry);
}

/*
 * nss_cryptoapi_aead_init()
 * 	Cryptoapi aead init function.
 */
static int nss_cryptoapi_aead_init(struct crypto_tfm *tfm)
{
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(tfm);

	nss_cfi_assert(ctx);

	ctx->sid = NSS_CRYPTO_MAX_IDXS;
	ctx->queued = 0;
	ctx->completed = 0;
	atomic_set(&ctx->refcnt, 0);

	nss_cryptoapi_set_magic(ctx);

	return 0;
}

/*
 * nss_cryptoapi_aead_exit()
 * 	Cryptoapi aead exit function.
 */
static void nss_cryptoapi_aead_exit(struct crypto_tfm *tfm)
{
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(tfm);
	struct nss_cryptoapi *sc = &gbl_ctx;
	nss_crypto_status_t status;

	nss_cfi_assert(ctx);

	if (!atomic_dec_and_test(&ctx->refcnt)) {
		nss_cfi_err("Process done is not completed, while exit is called\n");
		nss_cfi_assert(false);
	}

	nss_cryptoapi_debugfs_del_session(ctx);

	status = nss_crypto_session_free(sc->crypto, ctx->sid);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("unable to free session: idx %d\n", ctx->sid);
	}

	nss_cryptoapi_clear_magic(ctx);
}

/*
 * nss_cryptoapi_aead_extract_key()
 * 	Populate nss_crypto_key structures for cip and auth.
 */
static int nss_cryptoapi_aead_extract_key(const u8 *key, unsigned int keylen, struct nss_crypto_key *cip, struct nss_crypto_key *auth)
{
	struct rtattr *rta = (struct rtattr *)key;
	struct crypto_authenc_key_param *param;
	uint32_t enc_key_len, auth_key_len;

	if (!RTA_OK(rta, keylen)) {
		nss_cfi_err("badkey RTA attr NOT ok keylen: %d\n", keylen);
		return -EINVAL;
	}

	if (rta->rta_type != CRYPTO_AUTHENC_KEYA_PARAM) {
		nss_cfi_err("badkey rta_type != CRYPTO_AUTHENC_KEYA_PARAM, rta_type: %d\n", rta->rta_type);
		return -EINVAL;
	}

	if (RTA_PAYLOAD(rta) < sizeof(*param)) {
		nss_cfi_err("RTA_PAYLOAD < param: %d\n", sizeof(*param));
		return -EINVAL;
	}

	param = RTA_DATA(rta);

	key += RTA_ALIGN(rta->rta_len);
	keylen -= RTA_ALIGN(rta->rta_len);

	enc_key_len = be32_to_cpu(param->enckeylen);
	auth_key_len = keylen - enc_key_len;

	nss_cfi_assert(enc_key_len);
	nss_cfi_assert(auth_key_len);

	auth->key = key;
	auth->key_len = auth_key_len;

	cip->key = key + auth_key_len;
	cip->key_len = enc_key_len;

	return 0;
}

/*
 * nss_cryptoapi_aead_validate_key()
 * 	Validate max cip and auth key length.
 */
static int nss_cryptoapi_aead_validate_key(struct nss_crypto_key *key, uint32_t max_key_len)
{
	return key->key_len > max_key_len ? -EINVAL : 0;
}

/*
 * nss_cryptoapi_sha1_aes_setkey()
 * 	Cryptoapi setkey routine for sha1/aes.
 */
static int nss_cryptoapi_sha1_aes_setkey(struct crypto_aead *tfm, const u8 *key, unsigned int keylen)
{
	struct nss_cryptoapi_ctx *ctx = crypto_aead_ctx(tfm);
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_crypto_key cip = { .algo = NSS_CRYPTO_CIPHER_AES };
	struct nss_crypto_key auth = { .algo = NSS_CRYPTO_AUTH_SHA1_HMAC };
	uint32_t flag = CRYPTO_TFM_RES_BAD_KEY_LEN;
	nss_crypto_status_t status;

	/*
	 * validate magic number - init should be called before setkey
	 */
	nss_cryptoapi_verify_magic(ctx);

	if (atomic_cmpxchg(&ctx->refcnt, 0, 1)) {
		nss_cfi_err("reusing context, setkey is already called\n");
		return -EINVAL;
	}

	/*
	 * Extract and cipher and auth key
	 */
	if (nss_cryptoapi_aead_extract_key(key, keylen, &cip, &auth)) {
		nss_cfi_err("Invalid cryptoapi context\n");
		goto fail;
	}

	/*
	 * Validate keys
	 */
	if (nss_cryptoapi_aead_validate_key(&cip, NSS_CRYPTO_MAX_KEYLEN_AES)) {
		nss_cfi_err("Bad Cipher key\n");
		goto fail;
	}

	if (nss_cryptoapi_aead_validate_key(&auth, NSS_CRYPTO_MAX_KEYLEN_SHA1)) {
		nss_cfi_err("Bad Auth key\n");
		goto fail;
	}

	status = nss_crypto_session_alloc(sc->crypto, &cip, &auth, &ctx->sid);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("nss_crypto_session_alloc failed - status: %d\n", status);
		ctx->sid = NSS_CRYPTO_MAX_IDXS;
		flag = CRYPTO_TFM_RES_BAD_FLAGS;
		goto fail;
	}

	nss_cryptoapi_debugfs_add_session(sc, ctx);

	nss_cfi_info("session id created: %d\n", ctx->sid);

	ctx->cip_alg = NSS_CRYPTO_CIPHER_AES;
	ctx->auth_alg = NSS_CRYPTO_AUTH_SHA1_HMAC;

	return 0;

fail:
	crypto_aead_set_flags(tfm, flag);
	return -EINVAL;
}

/*
 * nss_cryptoapi_sha256_aes_setkey()
 * 	Cryptoapi setkey routine for sha256/aes.
 */
static int nss_cryptoapi_sha256_aes_setkey(struct crypto_aead *tfm, const u8 *key, unsigned int keylen)
{
	struct nss_cryptoapi_ctx *ctx = crypto_aead_ctx(tfm);
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_crypto_key cip = { .algo = NSS_CRYPTO_CIPHER_AES };
	struct nss_crypto_key auth = { .algo = NSS_CRYPTO_AUTH_SHA256_HMAC };
	uint32_t flag = CRYPTO_TFM_RES_BAD_KEY_LEN;
	nss_crypto_status_t status;

	/*
	 * validate magic number - init should be called before setkey
	 */
	nss_cryptoapi_verify_magic(ctx);

	if (atomic_cmpxchg(&ctx->refcnt, 0, 1)) {
		nss_cfi_err("reusing context, setkey is already called\n");
		return -EINVAL;
	}

	/*
	 * Extract and cipher and auth key
	 */
	if (nss_cryptoapi_aead_extract_key(key, keylen, &cip, &auth)) {
		nss_cfi_err("Bad Key\n");
		goto fail;
	}

	/*
	 * Validate keys
	 */
	if (nss_cryptoapi_aead_validate_key(&cip, NSS_CRYPTO_MAX_KEYLEN_AES)) {
		nss_cfi_err("Bad Cipher key\n");
		goto fail;
	}

	if (nss_cryptoapi_aead_validate_key(&auth, NSS_CRYPTO_MAX_KEYLEN_SHA256)) {
		nss_cfi_err("Bad Auth key\n");
		goto fail;
	}

	status = nss_crypto_session_alloc(sc->crypto, &cip, &auth, &ctx->sid);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("nss_crypto_session_alloc failed - status: %d\n", status);
		ctx->sid = NSS_CRYPTO_MAX_IDXS;
		flag = CRYPTO_TFM_RES_BAD_FLAGS;
		goto fail;
	}

	nss_cryptoapi_debugfs_add_session(sc, ctx);

	nss_cfi_info("session id created: %d\n", ctx->sid);

	ctx->cip_alg = NSS_CRYPTO_CIPHER_AES;
	ctx->auth_alg = NSS_CRYPTO_AUTH_SHA256_HMAC;

	return 0;

fail:
	crypto_aead_set_flags(tfm, flag);
	return -EINVAL;
}

/*
 * nss_cryptoapi_sha1_3des_setkey()
 * 	Cryptoapi setkey routine for sha1/3des.
 */
static int nss_cryptoapi_sha1_3des_setkey(struct crypto_aead *tfm, const u8 *key, unsigned int keylen)
{
	struct nss_cryptoapi_ctx *ctx = crypto_aead_ctx(tfm);
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_crypto_key cip = { .algo = NSS_CRYPTO_CIPHER_DES };
	struct nss_crypto_key auth = { .algo = NSS_CRYPTO_AUTH_SHA1_HMAC };
	uint32_t flag = CRYPTO_TFM_RES_BAD_KEY_LEN;
	nss_crypto_status_t status;

	/*
	 * validate magic number - init should be called before setkey
	 */
	nss_cryptoapi_verify_magic(ctx);

	if (atomic_cmpxchg(&ctx->refcnt, 0, 1)) {
		nss_cfi_err("reusing context, setkey is already called\n");
		return -EINVAL;
	}

	/*
	 * Extract and cipher and auth key
	 */
	if (nss_cryptoapi_aead_extract_key(key, keylen, &cip, &auth)) {
		nss_cfi_err("Bad Key\n");
		goto fail;
	}

	/*
	 * Validate keys
	 */
	if (nss_cryptoapi_aead_validate_key(&cip, NSS_CRYPTO_MAX_KEYLEN_DES)) {
		nss_cfi_err("Bad Cipher key\n");
		goto fail;
	}

	if (nss_cryptoapi_aead_validate_key(&auth, NSS_CRYPTO_MAX_KEYLEN_SHA1)) {
		nss_cfi_err("Bad Auth key\n");
		goto fail;
	}

	status = nss_crypto_session_alloc(sc->crypto, &cip, &auth, &ctx->sid);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("nss_crypto_session_alloc failed - status: %d\n", status);
		ctx->sid = NSS_CRYPTO_MAX_IDXS;
		flag = CRYPTO_TFM_RES_BAD_FLAGS;
		goto fail;
	}

	nss_cryptoapi_debugfs_add_session(sc, ctx);

	nss_cfi_info("session id created: %d\n", ctx->sid);

	ctx->cip_alg = NSS_CRYPTO_CIPHER_DES;
	ctx->auth_alg = NSS_CRYPTO_AUTH_SHA1_HMAC;

	return 0;

fail:
	crypto_aead_set_flags(tfm, flag);
	return -EINVAL;
}

/*
 * nss_cryptoapi_sha256_3des_setkey()
 * 	Cryptoapi setkey routine for sha256/3des.
 */
static int nss_cryptoapi_sha256_3des_setkey(struct crypto_aead *tfm, const u8 *key, unsigned int keylen)
{
	struct nss_cryptoapi_ctx *ctx = crypto_aead_ctx(tfm);
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_crypto_key cip = { .algo = NSS_CRYPTO_CIPHER_DES };
	struct nss_crypto_key auth = { .algo = NSS_CRYPTO_AUTH_SHA256_HMAC };
	uint32_t flag = CRYPTO_TFM_RES_BAD_KEY_LEN;
	nss_crypto_status_t status;

	/*
	 * validate magic number - init should be called before setkey
	 */
	nss_cryptoapi_verify_magic(ctx);

	if (atomic_cmpxchg(&ctx->refcnt, 0, 1)) {
		nss_cfi_err("reusing context, setkey is already called\n");
		return -EINVAL;
	}

	/*
	 * Extract and cipher and auth key
	 */
	if (nss_cryptoapi_aead_extract_key(key, keylen, &cip, &auth)) {
		nss_cfi_err("Bad Key\n");
		goto fail;
	}

	/*
	 * Validate keys
	 */
	if (nss_cryptoapi_aead_validate_key(&cip, NSS_CRYPTO_MAX_KEYLEN_DES)) {
		nss_cfi_err("Bad Cipher key\n");
		goto fail;
	}

	if (nss_cryptoapi_aead_validate_key(&auth, NSS_CRYPTO_MAX_KEYLEN_SHA256)) {
		nss_cfi_err("Bad Auth key\n");
		goto fail;
	}

	status = nss_crypto_session_alloc(sc->crypto, &cip, &auth, &ctx->sid);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("nss_crypto_session_alloc failed - status: %d\n", status);
		ctx->sid = NSS_CRYPTO_MAX_IDXS;
		flag = CRYPTO_TFM_RES_BAD_FLAGS;
		goto fail;
	}

	nss_cryptoapi_debugfs_add_session(sc, ctx);

	nss_cfi_info("session id created: %d\n", ctx->sid);

	ctx->cip_alg = NSS_CRYPTO_CIPHER_DES;
	ctx->auth_alg = NSS_CRYPTO_AUTH_SHA256_HMAC;

	return 0;

fail:
	crypto_aead_set_flags(tfm, flag);
	return -EINVAL;
}

/*
 * nss_cryptoapi_aead_setauthsize()
 * 	Cryptoapi set authsize funtion.
 */

static int nss_cryptoapi_aead_setauthsize(struct crypto_aead *authenc, unsigned int authsize)
{
	/*
	 * Store the authsize.
	 */
	struct nss_cryptoapi_ctx *ctx = crypto_aead_ctx(authenc);

	ctx->authsize = authsize;
	return 0;
}

/*
 * nss_cryptoapi_process_done()
 * 	Cipher/Auth operation completion callback function
 */
static void nss_cryptoapi_process_done(struct nss_crypto_buf *buf)
{
	struct nss_cryptoapi_ctx *ctx;
	struct aead_request *req;
	uint8_t *data_hmac;
	uint8_t *hw_hmac;
	uint32_t hmac_sz;
	int err = 0;

	nss_cfi_assert(buf);

	nss_cfi_dbg_data(buf->data, buf->data_len, ' ');

	req = (struct aead_request *)buf->cb_ctx;

	ctx = crypto_tfm_ctx(req->base.tfm);
	nss_cryptoapi_verify_magic(ctx);

	hmac_sz = nss_cryptoapi_get_hmac_sz(req);
	hw_hmac = buf->data + buf->data_len - hmac_sz;
	data_hmac = hw_hmac - hmac_sz;

	/*
	 * check cryptoapi context magic number.
	 */

	if (nss_cryptoapi_is_decrypt(ctx) && memcmp(hw_hmac, data_hmac, hmac_sz)) {
		err = -EBADMSG;
		nss_cfi_err("HMAC comparison failed\n");
	}

	nss_crypto_buf_free(gbl_ctx.crypto, buf);
	/*
	 * Passing always pass in case of encrypt.
	 * Perhaps whenever core crypto invloke callback routine, it is always pass.
	 */
	aead_request_complete(req, err);

	nss_cfi_assert(atomic_read(&ctx->refcnt));
	atomic_dec(&ctx->refcnt);
	ctx->completed++;
}

/*
 * nss_cryptoapi_validate_addr()
 * 	Cipher/Auth operation valiate virtual addresses of sg's
 */
static int nss_cryptoapi_validate_addr(struct nss_cryptoapi_addr *sg_addr)
{
	/*
	 * Currently only in-place transformation is supported.
	 */
	if (sg_addr->src != sg_addr->dst) {
		nss_cfi_err("src!=dst src: 0x%p, dst: 0x%p\n", sg_addr->src, sg_addr->dst);
		return -EINVAL;
	}

	/*
	 * Assoc should include IV, should be before cipher.
	 */
	if (sg_addr->src < sg_addr->start) {
		nss_cfi_err("Invalid cipher pointer src: 0x%p, iv: 0x%p, assoc: 0x%p\n", sg_addr->src, sg_addr->iv, sg_addr->assoc);
		return -EINVAL;
	}

	return 0;
}

/*
 * nss_cryptoapi_checknget_addr()
 * 	Cryptoapi: obtain sg to virtual address mapping.
 * 	Check for multiple sg in src, dst and assoc sg_list validate virtual address laytou
 */
static int nss_cryptoapi_checknget_addr(struct aead_request *req, struct nss_cryptoapi_addr *sg_addr)
{
	/*
	 * Currently only single sg is supported
	 * 	return error, if caller send multiple sg for any of src, assoc and dst.
	 */
	if (nss_cryptoapi_sg_has_frags(req->src)) {
		nss_cfi_err("Only single sg supported: src invalid\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_sg_has_frags(req->dst)) {
		nss_cfi_err("Only single sg supported: dst invalid\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_sg_has_frags(req->assoc)) {
		nss_cfi_err("Only single sg supported: assoc invalid\n");
		return -EINVAL;
	}

	/*
	 * check start of buffer.
	 * Either of assoc or iv can be start of the data
	 */
	sg_addr->src = sg_virt(req->src);
	sg_addr->dst = sg_virt(req->dst);
	sg_addr->assoc = sg_virt(req->assoc);
	sg_addr->start = nss_cryptoapi_get_buf_addr(sg_addr->assoc, sg_addr->iv);

	nss_cfi_assert(sg_addr->src);
	nss_cfi_assert(sg_addr->dst);
	nss_cfi_assert(sg_addr->assoc);
	nss_cfi_assert(sg_addr->iv);
	nss_cfi_assert(sg_addr->start);

	if (nss_cryptoapi_validate_addr(sg_addr)) {
		nss_cfi_err("Invalid addresses\n");
		return -EINVAL;
	}

	return 0;
}

/*
 * nss_cryptoapi_aead_transform()
 * 	Crytoapi common routine for encryption and decryption operations.
 */
static struct nss_crypto_buf *nss_cryptoapi_aead_transform(struct aead_request *req, void *iv, struct nss_crypto_params *params)
{
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_buf *buf;
	struct nss_cryptoapi_addr sg_addr = {0};
	struct nss_cryptoapi *sc = &gbl_ctx;
	nss_crypto_status_t status;
	int tot_buf_len;
	uint16_t sha;
	uint16_t ivsize;

	nss_cfi_assert(ctx);

	/*
	 * Map sg to corresponding virtual addesses.
	 * validate if addresses are valid as expected and sg has single fragment.
	 */
	sg_addr.iv = iv;
	if (nss_cryptoapi_checknget_addr(req, &sg_addr)) {
		nss_cfi_err("Invalid address!!\n");
		return NULL;
	}

	nss_cfi_dbg("src_vaddr: 0x%p, dst_vaddr: 0x%p, assoc_vaddr: 0x%p, iv: 0x%p\n",
			sg_addr.src, sg_addr.dst, sg_addr.assoc, sg_addr.iv);

	params->cipher_skip = nss_cryptoapi_get_skip(sg_addr.src, sg_addr.start);
	params->auth_skip = nss_cryptoapi_get_skip(sg_addr.assoc, sg_addr.start);

	/*
	 * Update the crypto session data
	 */
	status = nss_crypto_session_update(sc->crypto, ctx->sid, params);
	if (status != NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Invalid crypto session parameters\n");
		return NULL;
	}

	/*
	 * Allocate crypto buf
	 */
	buf = nss_crypto_buf_alloc(sc->crypto);
	if (!buf) {
		nss_cfi_err("not able to allocate crypto buffer\n");
		return NULL;
	}

	/*
	 *  filling up buffer entries
	 */
	buf->cb_ctx = (uint32_t)req;
	buf->cb_fn = nss_cryptoapi_process_done;
	buf->session_idx = ctx->sid;

	sha = nss_cryptoapi_get_hmac_sz(req);
	ivsize = nss_cryptoapi_get_iv_sz(req);

	/*
	 * Fill cipher info in buf:
	 */
	buf->cipher_len = req->cryptlen;
	buf->iv_offset = nss_cryptoapi_get_skip(sg_addr.iv, sg_addr.start);
	buf->iv_len = ivsize;

	tot_buf_len = req->assoclen + ivsize + req->cryptlen;

	/*
	 * Fill Auth info in buf
	 */
	buf->auth_len = tot_buf_len;
	buf->hash_offset = tot_buf_len;

	/*
	 * In case of decrypt operation, ipsec include hmac size in req->cryptlen
	 * skip encryption and authentication on hmac trasmitted with data.
	 * TODO: fix this in future, pass relevant details from caller.
	 */
	ctx->op = params->req_type;
	if (nss_cryptoapi_is_decrypt(ctx)) {
		buf->cipher_len -= sha;
		buf->auth_len -= sha;
	}

	if (buf->cipher_len & (nss_cryptoapi_get_blocksize(req) - 1)) {
		nss_cfi_err("Invalid cipher len - Not aligned to algo blocksize\n");
		nss_crypto_buf_free(sc->crypto, buf);
		crypto_aead_set_flags(crypto_aead_reqtfm(req), CRYPTO_TFM_RES_BAD_BLOCK_LEN);
		return NULL;
	}

	/*
	 * The physical buffer data length provided to crypto will include
	 * space for authentication hash
	 */
	buf->data_len = tot_buf_len + sha;
	buf->data = sg_addr.start;


	nss_cfi_dbg("cipher_len: %d, iv_offset: %d, iv_len: %d, auth_len: %d, hash_offset: %d"
			"tot_buf_len: %d, sha: %d, cipher_skip: %d, auth_skip: %d\n",
			buf->cipher_len, buf->iv_offset, buf->iv_len, buf->auth_len, buf->hash_offset,
			tot_buf_len, sha, params->cipher_skip, params->auth_skip);
	nss_cfi_dbg_data(buf->data, buf->data_len, ' ');

	return buf;
}

/*
 * nss_cryptoapi_check_alg()
 * 	Cryptoapi verify cip and auth algo with what was used during session id creation.
 */
static int nss_cryptoapi_check_alg(struct nss_cryptoapi_ctx *ctx, enum nss_crypto_cipher cip, enum nss_crypto_auth auth)
{
	return (ctx->cip_alg != cip || ctx->auth_alg != auth) ? -EINVAL : 0;
}

/*
 * nss_cryptoapi_sha1_aes_encrypt()
 * 	Crytoapi encrypt for sha1/aes algorithm.
 */
static int nss_cryptoapi_sha1_aes_encrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_aes_encrypt()
 * 	Crytoapi encrypt for sha256/aes algorithm.
 */
static int nss_cryptoapi_sha256_aes_encrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}


/*
 * nss_cryptoapi_sha1_3des_encrypt()
 * 	Crytoapi encrypt for sha1/3des algorithm.
 */
static int nss_cryptoapi_sha1_3des_encrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}


	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_3des_encrypt()
 * 	Crytoapi encrypt for sha256/3des algorithm.
 */
static int nss_cryptoapi_sha256_3des_encrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha1_aes_decrypt()
 * 	Crytoapi decrypt for sha1/aes algorithm.
 */
static int nss_cryptoapi_sha1_aes_decrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_DECRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_aes_decrypt()
 * 	Crytoapi decrypt for sha256/aes algorithm.
 */
static int nss_cryptoapi_sha256_aes_decrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_DECRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha1_3des_decrypt()
 * 	Crytoapi decrypt for sha1/3des algorithm.
 */
static int nss_cryptoapi_sha1_3des_decrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_DECRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}


	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_3des_decrypt()
 * 	Crytoapi decrypt for sha256/3des algorithm.
 */
static int nss_cryptoapi_sha256_3des_decrypt(struct aead_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_DECRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}


	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	buf = nss_cryptoapi_aead_transform(req, req->iv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha1_aes_geniv_encrypt()
 * 	Crytoapi generate IV encrypt for sha1/aes algorithm.
 */
static int nss_cryptoapi_sha1_aes_geniv_encrypt(struct aead_givcrypt_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->areq.base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for session id: %d\n", ctx->sid);
		return -EINVAL;
	}

	/*
	 * fill in iv.
	 */
	get_random_bytes(req->giv, AES_BLOCK_SIZE);

	buf = nss_cryptoapi_aead_transform(&req->areq, req->giv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_aes_geniv_encrypt()
 * 	Crytoapi generate IV encrypt for sha256/aes algorithm.
 */
static int nss_cryptoapi_sha256_aes_geniv_encrypt(struct aead_givcrypt_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->areq.base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_AES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	/*
	 * fill in iv.
	 */
	get_random_bytes(req->giv, AES_BLOCK_SIZE);

	buf = nss_cryptoapi_aead_transform(&req->areq, req->giv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha1_3des_geniv_encrypt()
 * 	Crytoapi generate IV encrypt for sha1/3des algorithm.
 */
static int nss_cryptoapi_sha1_3des_geniv_encrypt(struct aead_givcrypt_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->areq.base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA1_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	/*
	 * fill in iv.
	 */
	get_random_bytes(req->giv, DES3_EDE_BLOCK_SIZE);

	buf = nss_cryptoapi_aead_transform(&req->areq, req->giv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * nss_cryptoapi_sha256_3des_geniv_encrypt()
 * 	Crytoapi generate IV encrypt for sha256/3des algorithm.
 */
static int nss_cryptoapi_sha256_3des_geniv_encrypt(struct aead_givcrypt_request *req)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	struct nss_cryptoapi_ctx *ctx = crypto_tfm_ctx(req->areq.base.tfm);
	struct nss_crypto_params params = { .req_type = NSS_CRYPTO_REQ_TYPE_AUTH |
							NSS_CRYPTO_REQ_TYPE_ENCRYPT };
	struct nss_crypto_buf *buf;

	/*
	 * check cryptoapi context magic number.
	 */
	nss_cryptoapi_verify_magic(ctx);

	/*
	 * Check if previous call to setkey couldn't allocate session with core crypto.
	 */
	if (ctx->sid >= NSS_CRYPTO_MAX_IDXS) {
		nss_cfi_err("Invalid session\n");
		return -EINVAL;
	}

	if (nss_cryptoapi_check_alg(ctx, NSS_CRYPTO_CIPHER_DES, NSS_CRYPTO_AUTH_SHA256_HMAC)) {
		nss_cfi_err("Invalid Algo for seesion id: %d\n", ctx->sid);
		return -EINVAL;
	}

	/*
	 * fill in iv.
	 */
	get_random_bytes(req->giv, DES3_EDE_BLOCK_SIZE);

	buf = nss_cryptoapi_aead_transform(&req->areq, req->giv, &params);
	if (!buf) {
		nss_cfi_err("Invalid parameters\n");
		return -EINVAL;
	}

	/*
	 *  Send the buffer to CORE layer for processing
	 */
	if (nss_crypto_transform_payload(sc->crypto, buf) !=  NSS_CRYPTO_STATUS_OK) {
		nss_cfi_err("Not enough resources with driver\n");
		nss_crypto_buf_free(sc->crypto, buf);
		return -EINVAL;
	}

	ctx->queued++;
	atomic_inc(&ctx->refcnt);

	return -EINPROGRESS;
}

/*
 * crypto_alg structure initialization
 * 	Only AEAD (Cipher and Authentication) is supported by core crypto driver.
 */

static struct crypto_alg cryptoapi_aead_algos[] = {
	{	/* sha1, aes */
		.cra_name       = "authenc(hmac(sha1),cbc(aes))",
		.cra_driver_name = "cryptoapi-aead-hmac-sha1-cbc-aes",
		.cra_priority   = 300,
		.cra_flags      = CRYPTO_ALG_TYPE_AEAD | CRYPTO_ALG_ASYNC,
		.cra_blocksize  = AES_BLOCK_SIZE,
		.cra_ctxsize    = sizeof(struct nss_cryptoapi_ctx),
		.cra_alignmask  = 0,
		.cra_type       = &crypto_aead_type,
		.cra_module     = THIS_MODULE,
		.cra_init       = nss_cryptoapi_aead_init,
		.cra_exit       = nss_cryptoapi_aead_exit,
		.cra_u          = {
			.aead = {
				.ivsize         = AES_BLOCK_SIZE,
				.maxauthsize    = SHA1_DIGEST_SIZE,
				.setkey = nss_cryptoapi_sha1_aes_setkey,
				.setauthsize = nss_cryptoapi_aead_setauthsize,
				.encrypt = nss_cryptoapi_sha1_aes_encrypt,
				.decrypt = nss_cryptoapi_sha1_aes_decrypt,
				.givencrypt = nss_cryptoapi_sha1_aes_geniv_encrypt,
				.geniv = "<built-in>",
			}
		}
	},
	{	/* sha1, 3des */
		.cra_name       = "authenc(hmac(sha1),cbc(des3_ede))",
		.cra_driver_name = "cryptoapi-aead-hmac-sha1-cbc-3des",
		.cra_priority   = 300,
		.cra_flags      = CRYPTO_ALG_TYPE_AEAD | CRYPTO_ALG_ASYNC,
		.cra_blocksize  = DES3_EDE_BLOCK_SIZE,
		.cra_ctxsize    = sizeof(struct nss_cryptoapi_ctx),
		.cra_alignmask  = 0,
		.cra_type       = &crypto_aead_type,
		.cra_module     = THIS_MODULE,
		.cra_init       = nss_cryptoapi_aead_init,
		.cra_exit       = nss_cryptoapi_aead_exit,
		.cra_u          = {
			.aead = {
				.ivsize         = DES3_EDE_BLOCK_SIZE,
				.maxauthsize    = SHA1_DIGEST_SIZE,
				.setkey = nss_cryptoapi_sha1_3des_setkey,
				.setauthsize = nss_cryptoapi_aead_setauthsize,
				.encrypt = nss_cryptoapi_sha1_3des_encrypt,
				.decrypt = nss_cryptoapi_sha1_3des_decrypt,
				.givencrypt = nss_cryptoapi_sha1_3des_geniv_encrypt,
				.geniv = "<built-in>",
			}
		}
	},
	{	/* sha256, aes */
		.cra_name       = "authenc(hmac(sha256),cbc(aes))",
		.cra_driver_name = "cryptoapi-aead-hmac-sha256-cbc-aes",
		.cra_priority   = 300,
		.cra_flags      = CRYPTO_ALG_TYPE_AEAD | CRYPTO_ALG_ASYNC,
		.cra_blocksize  = AES_BLOCK_SIZE,
		.cra_ctxsize    = sizeof(struct nss_cryptoapi_ctx),
		.cra_alignmask  = 0,
		.cra_type       = &crypto_aead_type,
		.cra_module     = THIS_MODULE,
		.cra_init       = nss_cryptoapi_aead_init,
		.cra_exit       = nss_cryptoapi_aead_exit,
		.cra_u          = {
			.aead = {
				.ivsize         = AES_BLOCK_SIZE,
				.maxauthsize    = SHA256_DIGEST_SIZE,
				.setkey = nss_cryptoapi_sha256_aes_setkey,
				.setauthsize = nss_cryptoapi_aead_setauthsize,
				.encrypt = nss_cryptoapi_sha256_aes_encrypt,
				.decrypt = nss_cryptoapi_sha256_aes_decrypt,
				.givencrypt = nss_cryptoapi_sha256_aes_geniv_encrypt,
				.geniv = "<built-in>",
			}
		}
	},
	{	/* sha256, 3des */
		.cra_name       = "authenc(hmac(sha256),cbc(des3_ede))",
		.cra_driver_name = "cryptoapi-aead-hmac-sha256-cbc-3des",
		.cra_priority   = 300,
		.cra_flags      = CRYPTO_ALG_TYPE_AEAD | CRYPTO_ALG_ASYNC,
		.cra_blocksize  = DES3_EDE_BLOCK_SIZE,
		.cra_ctxsize    = sizeof(struct nss_cryptoapi_ctx),
		.cra_alignmask  = 0,
		.cra_type       = &crypto_aead_type,
		.cra_module     = THIS_MODULE,
		.cra_init       = nss_cryptoapi_aead_init,
		.cra_exit       = nss_cryptoapi_aead_exit,
		.cra_u          = {
			.aead = {
				.ivsize         = DES3_EDE_BLOCK_SIZE,
				.maxauthsize    = SHA256_DIGEST_SIZE,
				.setkey = nss_cryptoapi_sha256_3des_setkey,
				.setauthsize = nss_cryptoapi_aead_setauthsize,
				.encrypt = nss_cryptoapi_sha256_3des_encrypt,
				.decrypt = nss_cryptoapi_sha256_3des_decrypt,
				.givencrypt = nss_cryptoapi_sha256_3des_geniv_encrypt,
				.geniv = "<built-in>",
			}
		}
	},

};

/*
 * nss_cryptoapi_register()
 * 	register crypto core with the cryptoapi CFI
 */
static nss_crypto_user_ctx_t nss_cryptoapi_register(nss_crypto_handle_t crypto)
{
	int i;
	int rc = 0;
	struct nss_cryptoapi *sc = &gbl_ctx;

	nss_cfi_info("register nss_cryptoapi with core\n");

	sc->crypto = crypto;

	for (i = 0; i < ARRAY_SIZE(cryptoapi_aead_algos); i++) {

		rc = crypto_register_alg(&cryptoapi_aead_algos[i]);
		if (rc) {
			nss_cfi_err("Aead registeration failed, algo: %s\n", cryptoapi_aead_algos[i].cra_name);
			continue;
		}
		nss_cfi_info("Aead registeration succeed, algo: %s\n", cryptoapi_aead_algos[i].cra_name);
	}

	/*
	 * Initialize debugfs for cryptoapi.
	 */
	nss_cryptoapi_debugfs_init(sc);

	return sc;
}

/*
 * nss_cryptoapi_unregister()
 * 	Unregister crypto core with cryptoapi CFI layer
 */
static void nss_cryptoapi_unregister(nss_crypto_user_ctx_t cfi)
{
	struct nss_cryptoapi *sc = &gbl_ctx;
	nss_cfi_info("unregister nss_cryptoapi\n");

        /*
         * cleanup cryptoapi debugfs.
         */
        nss_cryptoapi_debugfs_exit(sc);
}

/*
 * nss_cryptoapi_init()
 * 	Initializing crypto core layer
 */
int nss_cryptoapi_init(void)
{
	nss_crypto_register_user(nss_cryptoapi_register, nss_cryptoapi_unregister, "nss_cryptoapi");
	nss_cfi_info("initialize nss_cryptoapi\n");

	return 0;
}

/*
 * nss_cryptoapi_exit()
 * 	De-Initialize cryptoapi CFI layer
 */
void nss_cryptoapi_exit(void)
{
	nss_cfi_info("exiting nss_cryptoapi\n");
}

MODULE_LICENSE("Dual BSD/GPL");

module_init(nss_cryptoapi_init);
module_exit(nss_cryptoapi_exit);
