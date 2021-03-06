/*
 **************************************************************************
 * Copyright (c) 2015, The Linux Foundation. All rights reserved.
 * Permission to use, copy, modify, and/or distribute this software for
 * any purpose with or without fee is hereby granted, provided that the
 * above copyright notice and this permission notice appear in all copies.
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 **************************************************************************
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/version.h>
#include <linux/if.h>
#include <linux/netlink.h>
#include <net/genetlink.h>

#include <nss_api_if.h>
#include <nss_nl_if.h>
#include "nss_ipsecmgr.h"
#include "nss_nlcmn_if.h"
#include "nss_crypto_if.h"
#include "nss_nlipv4_if.h"
#include "nss_nlcrypto_if.h"
#include "nss_nlipsec_if.h"

#include "nss_nl.h"
#include "nss_nlipv4.h"
#include "nss_nlcrypto.h"
#include "nss_nlipsec.h"

/*
 * nss_nl.c
 *	NSS Netlink manager
 */

/*
 * NSS NL family definition
 */
struct nss_nl_family {
	uint8_t *name;		/* name of the family */
	nss_nl_fn_t entry;	/* entry function of the family */
	nss_nl_fn_t exit;	/* exit function of the family */
	bool valid;		/* valid or invalid */
};

/*
 * Family handler table
 */
static struct nss_nl_family family_handlers[] = {
	{
		/*
		 * NSS_NLCRYPTO
		 */
		.name = NSS_NLCRYPTO_FAMILY,		/* crypto */
		.entry = NSS_NLCRYPTO_INIT,		/* init */
		.exit = NSS_NLCRYPTO_EXIT,		/* exit */
		.valid = CONFIG_NSS_NLCRYPTO		/* 1 or 0 */
	},
	{
		/*
		 * NSS_NLIPV4
		 */
		.name = NSS_NLIPV4_FAMILY,		/* ipv4 */
		.entry = NSS_NLIPV4_INIT,		/* init */
		.exit = NSS_NLIPV4_EXIT,		/* exit */
		.valid = CONFIG_NSS_NLIPV4		/* 1 or 0 */
	},
	{
		/*
		 * NSS_NLIPSEC
		 */
		.name = NSS_NLIPSEC_FAMILY,		/* ipsec */
		.entry = NSS_NLIPSEC_INIT,		/* init */
		.exit = NSS_NLIPSEC_EXIT,		/* exit */
		.valid = CONFIG_NSS_NLIPSEC		/* 1 or 0 */
	},
};

#define NSS_NL_FAMILY_HANDLER_SZ ARRAY_SIZE(family_handlers)


/*
 * nss_nl_alloc_msg()
 * 	allocate NETLINK message
 *
 * NOTE: this returns the SKB/message
 */
struct sk_buff *nss_nl_new_msg(struct genl_family *family, uint8_t cmd)
{
	struct sk_buff *skb;
	struct nss_nlcmn *cm;
	int len;

	/*
	 * aligned length
	 */
	len = nla_total_size(family->hdrsize);

	/*
	 * allocate NL message
	 */
	skb = genlmsg_new(len, GFP_ATOMIC);
	if (!skb) {
		nss_nl_error("%s: unable to allocate notifier SKB\n", family->name);
		return NULL;
	}

	/*
	 * append the generic message header
	 */
	cm = genlmsg_put(skb, 0 /*pid*/, 0 /*seq*/, family, 0 /*flags*/, cmd);
	if (!cm) {
		nss_nl_error("%s: no space to put generic header\n", family->name);
		nlmsg_free(skb);
		return NULL;
	}

	/*
	 * Kernel PID=0
	 */
	cm->pid = 0;

	return skb;
}

/*
 * nss_nl_copy_msg()
 * 	copy a existing NETLINK message into a new one
 *
 * NOTE: this returns the new SKB/message
 */
struct sk_buff *nss_nl_copy_msg(struct sk_buff *orig)
{
	struct sk_buff *copy;
	struct nss_nlcmn *cm;

	cm = nss_nl_get_data(orig);

	copy = skb_copy(orig, GFP_KERNEL);
	if (!copy) {
		nss_nl_error("%d:unable to copy incoming message of len(%d)\n", cm->pid, orig->len);
		return NULL;
	}

	return copy;
}
/*
 * nss_nl_get_data()
 * 	Returns start of payload data
 */
void  *nss_nl_get_data(struct sk_buff *skb)
{
	return genlmsg_data(NLMSG_DATA(skb->data));
}

/*
 * nss_nl_mcast_event()
 * 	mcast the event to the user listening on the MCAST group ID
 *
 * Note: It will free the message buffer if there is no space left to end
 */
int nss_nl_mcast_event(struct genl_multicast_group *grp, struct sk_buff *skb)
{
	struct nss_nlcmn *cm;

	cm = genlmsg_data(NLMSG_DATA(skb->data));
	/*
	 * End the message as no more updates are left to happen.
	 * After this, the message is assunmed to be read-only
	 */
	if (genlmsg_end(skb, cm) < 0) {
		nss_nl_error("%s: unable to close generic mcast message\n", grp->family->name);
		nlmsg_free(skb);
		return -ENOMEM;
	}

	return genlmsg_multicast(skb, cm->pid, grp->id, GFP_ATOMIC);
}

/*
 * nss_nl_ucast_resp()
 * 	send the response to the user (PID)
 *
 * NOTE: this assumes the socket to be available for reception
 */
int nss_nl_ucast_resp(struct sk_buff *skb)
{
	struct nss_nlcmn *cm;
	struct net *net;

	cm = genlmsg_data(NLMSG_DATA(skb->data));

	net = (struct net *)cm->sock_data;
	cm->sock_data = 0;

	/*
	 * End the message as no more updates are left to happen
	 * After this message is assumed to be read-only
	 */
	if (genlmsg_end(skb, cm) < 0) {
		nss_nl_error("%d: unable to close generic ucast message\n", cm->pid);
		nlmsg_free(skb);
		return -ENOMEM;
	}

	return genlmsg_unicast(net, skb, cm->pid);
}

/*
 * nss_nl_get_msg()
 * 	verifies and returns the message pointer
 */
struct nss_nlcmn *nss_nl_get_msg(struct genl_family *family, struct genl_info *info, uint16_t cmd)
{
	struct nss_nlcmn *cm;
	uint32_t pid;

#if (LINUX_VERSION_CODE < KERNEL_VERSION(3,7,0))
	pid =  info->snd_pid;
#else
	pid =  info->snd_portid;
#endif
	/*
	 * validate the common message header version & magic
	 */
	cm = info->userhdr;
	if (nss_nlcmn_chk_ver(cm, family->version) == false) {
		nss_nl_error("%d, %s: version mismatch (%d)\n", pid, family->name, cm->version);
		return NULL;
	}

	/*
	 * check if the message len arrived matches with expected len
	 */
	if (nss_nlcmn_get_len(cm) != family->hdrsize) {
		nss_nl_error("%d, %s: invalid command len (%d)\n", pid, family->name, nss_nlcmn_get_len(cm));
		return NULL;
	}

	cm->pid = pid;
	cm->sock_data = (uint32_t)genl_info_net(info);

	return cm;
}

/*
 * nss_nl_init()
 * 	init module
 */
static int __init nss_nl_init(void)
{
	struct nss_nl_family *family = NULL;
	int i = 0;

	nss_nl_info_always("NSS Netlink manager loaded: Build date %s\n", __DATE__);

	/*
	 * initialize the handler families, the intention to init the
	 * families that are marked active
	 */
	family = &family_handlers[0];

	for (i = 0; i < NSS_NL_FAMILY_HANDLER_SZ; i++, family++) {
		/*
		 * Check if the family exists
		 */
		if (!family->valid || !family->entry) {
			nss_nl_info_always("skipping family:%s\n", family->name);
			nss_nl_info_always("valid = %d, entry = %d\n", family->valid, !!family->entry);
			continue;
		}

		nss_nl_info_always("attaching family:%s\n", family->name);

		family->entry();
	}

	return 0;
}

/*
 * nss_nl_exit()
 * 	deinit module
 */
static void __exit nss_nl_exit(void)
{
	struct nss_nl_family *family = NULL;
	int i = 0;

	nss_nl_info_always("NSS Netlink manager unloaded\n");

	/*
	 * initialize the handler families
	 */
	family = &family_handlers[0];

	for (i = 0; i < NSS_NL_FAMILY_HANDLER_SZ; i++, family++) {
		/*
		 * Check if the family exists
		 */
		if (!family->valid || !family->exit) {
			nss_nl_info_always("skipping family:%s\n", family->name);
			nss_nl_info_always("valid = %d, exit = %d\n", family->valid, !!family->exit);
			continue;
		}

		nss_nl_info_always("detaching family:%s\n", family->name);

		family->exit();
	}
}

module_init(nss_nl_init);
module_exit(nss_nl_exit);

MODULE_DESCRIPTION("NSS NETLINK");
MODULE_LICENSE("Dual BSD/GPL");
