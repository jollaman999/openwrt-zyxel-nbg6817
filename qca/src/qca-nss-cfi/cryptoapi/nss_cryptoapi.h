/* Copyright (c) 2015, The Linux Foundation. All rights reserved.
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
 * nss_cryptoapi.h
 * 	Cryptoapi (Linux Crypto API framework) specific nss cfi header file
 */

/*
 *  @brief Cryptoapi sg virtual addresses
 * 	used during Encryption/Decryption operations.
 */
struct nss_cryptoapi_addr {
	uint8_t *src;
	uint8_t *dst;
	uint8_t *assoc;
	uint8_t *iv;
	uint8_t *start;
};

/**
 * @brief Framework specific handle this will be used to communicate framework
 *		specific data to Core specific data
 */
struct nss_cryptoapi {
	nss_crypto_handle_t crypto;		/**< crypto handle */
	struct dentry *root_dentry;
	struct dentry *stats_dentry;
};

struct nss_cryptoapi_ctx {
	uint64_t queued;
	uint64_t completed;
	uint32_t sid;
	unsigned int authsize;
	enum nss_crypto_cipher cip_alg;
	enum nss_crypto_auth auth_alg;
	enum nss_crypto_req_type op;
	struct dentry *session_dentry;
	atomic_t refcnt;
	uint16_t magic;
	uint16_t rsvd;
};

#define NSS_CRYPTOAPI_DEBUGFS_NAME_SZ 64

#define CRYPTOAPI_MAX_KEY_SIZE 64
#define NSS_CRYPTOAPI_MAGIC 0x1fff

static inline void nss_cryptoapi_verify_magic(struct nss_cryptoapi_ctx *ctx)
{
	BUG_ON(unlikely(ctx->magic != NSS_CRYPTOAPI_MAGIC));
}

static inline void nss_cryptoapi_set_magic(struct nss_cryptoapi_ctx *ctx)
{
	ctx->magic = NSS_CRYPTOAPI_MAGIC;
}

static inline void nss_cryptoapi_clear_magic(struct nss_cryptoapi_ctx *ctx)
{
	ctx->magic = 0;
}

static inline bool nss_cryptoapi_is_decrypt(struct nss_cryptoapi_ctx *ctx)
{
	return ctx->op & NSS_CRYPTO_REQ_TYPE_DECRYPT;
}

static inline uint8_t *nss_cryptoapi_get_buf_addr(uint8_t *addr_0, uint8_t *addr_1)
{
	return (addr_0 < addr_1) ? addr_0 : addr_1;
}

static inline uint8_t nss_cryptoapi_get_skip(uint8_t *addr, uint8_t *start)
{
	return addr - start;
}

static inline uint32_t nss_cryptoapi_get_hmac_sz(struct aead_request *req)
{
	return crypto_aead_authsize(crypto_aead_reqtfm(req));
}

static inline uint32_t nss_cryptoapi_get_blocksize(struct aead_request *req)
{
	return crypto_aead_blocksize(crypto_aead_reqtfm(req));
}

static inline uint32_t nss_cryptoapi_get_iv_sz(struct aead_request *req)
{
	return crypto_aead_ivsize(crypto_aead_reqtfm(req));
}

