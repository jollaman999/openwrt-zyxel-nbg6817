/*
 *  QCA Hy-Fi ECM
 *
 * Copyright (c) 2014, The Linux Foundation. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <linux/kernel.h>
#include <linux/export.h>
#include <linux/types.h>
#include <linux/skbuff.h>
#include <linux/etherdevice.h>
#include "hyfi_hash.h"
#include "hyfi_hatbl.h"
#include "hyfi_ecm.h"

int hyfi_ecm_new_connection(struct sk_buff *skb, u_int32_t ecm_serial, u_int32_t *hash)
{
	u_int32_t flag, priority, traffic_class, local_hash;
	u_int16_t seq;
	struct net_hatbl_entry *ha = NULL;
	struct hyfi_net_bridge *hyfi_br;

	if(!skb || !hash)
		return -1;

	hyfi_br = hyfi_bridge_get_by_dev(skb->dev);

	if(!hyfi_br) {
#if 0
		printk("%s: device %s not in bridge, serial %u\n",__func__, skb->dev->name, ecm_serial);
#endif
		return 0;
	}

	/* Compute the hash */
	if (unlikely(hyfi_hash_skbuf(skb, &local_hash, &flag, &priority, &seq)))
		return -1;

	traffic_class = (flag & IS_IPPROTO_UDP) ?
			HYFI_TRAFFIC_CLASS_UDP : HYFI_TRAFFIC_CLASS_OTHER;

	spin_lock_bh(&hyfi_br->hash_ha_lock);

	/* Find H-Active entry */
	ha = hatbl_find(hyfi_br, local_hash, eth_hdr(skb)->h_dest,
				traffic_class, priority);

	if (ha) {
		/* Found. Update ecm serial number and return the hash */
		ha->ecm_serial = ecm_serial;
		*hash = local_hash;

		spin_unlock_bh(&hyfi_br->hash_ha_lock);
#if 0
		printk("hyfi: New accelerated connection with serial number: %d, hash: 0x%02x, device: %s\n", ecm_serial, *hash, skb->dev->name);
#endif
		return 0;

	} else {
		/* H-Active was not found, look for H-Default entry, and create an
		 * H-Active entry if exists.
		 */
		struct net_hdtbl_entry *hd;

		/* Unlock the ha-lock, and lock the hd-lock */
		spin_unlock_bh(&hyfi_br->hash_ha_lock);

		spin_lock_bh(&hyfi_br->hash_hd_lock);
		hd = hyfi_hdtbl_find(hyfi_br, eth_hdr(skb)->h_dest);

		if (hd) {
			/* Create a new entry based on H-Default table. The function
			 * will keep the ha-lock if created successfully. */
			ha = hyfi_hatbl_insert_ecm_classifier(hyfi_br, local_hash,
					traffic_class, hd, priority,
					eth_hdr(skb)->h_source, ecm_serial);

			/* Release the hd-lock, we are done with the hd entry */
			spin_unlock_bh(&hyfi_br->hash_hd_lock);

			if(ha) {
				/* H-Active created. */
				*hash = local_hash;
				spin_unlock_bh(&hyfi_br->hash_ha_lock);
			}
		} else {
			/* No such H-Default entry, unlock hd-lock */
			spin_unlock_bh(&hyfi_br->hash_hd_lock);
		}
	}

	return 0;
}

EXPORT_SYMBOL(hyfi_ecm_new_connection);

int hyfi_ecm_update_stats(u_int32_t hash, u_int32_t ecm_serial, u_int64_t num_bytes, u_int64_t num_packets)
{
	struct net_hatbl_entry *ha = NULL;
	struct hyfi_net_bridge *hyfi_br = hyfi_bridge_get(HYFI_BRIDGE_ME);
	int ret = 0;

	if(!num_bytes || !num_packets)
		return 0;

	if(!hyfi_br)
		return -1;

	spin_lock_bh(&hyfi_br->hash_ha_lock);

	/* Find H-Active entry */
	if ((ha = hatbl_find_ecm(hyfi_br, hash, ecm_serial))) {
		if (!hyfi_ha_has_flag(ha, HYFI_HACTIVE_TBL_ACCL_ENTRY)) {

			/* This flow is now accelerated */
			hyfi_ha_set_flag(ha, HYFI_HACTIVE_TBL_ACCL_ENTRY);
			ha->prev_num_packets = num_packets;
			ha->prev_num_bytes = num_bytes;

			/* Flush seamless buffer - does not apply for accelerate flows */
			if (hyfi_ha_has_flag(ha, HYFI_HACTIVE_TBL_SEAMLESS_ENABLED)) {
				hyfi_ha_clear_flag(ha, HYFI_HACTIVE_TBL_SEAMLESS_ENABLED);
				hyfi_psw_flush_track_q(&ha->psw_stm_entry);
			}
		}

		ha->num_bytes += num_bytes - ha->prev_num_bytes;
		ha->num_packets += num_packets - ha->prev_num_packets;
		ha->prev_num_bytes = num_bytes;
		ha->prev_num_packets = num_packets;

#if 0
		printk("hyfi: Updated stats for hash 0x%02x, num_bytes=%d, num_packets=%d\n", hash, ha->num_bytes, ha->num_packets);
#endif
	} else {
		ret = -1;
	}

	spin_unlock_bh(&hyfi_br->hash_ha_lock);

	return ret;
}

EXPORT_SYMBOL(hyfi_ecm_update_stats);
