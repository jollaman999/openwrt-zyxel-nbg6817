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

#ifndef HYFI_ECM_H_
#define HYFI_ECM_H_

#include <linux/skbuff.h>
#include <linux/types.h>

/*
 * Notify about a new connection
 */
int hyfi_ecm_new_connection(struct sk_buff *skb, u_int32_t ecm_serial, u_int32_t *hash);

/*
 * Periodic stats updates
 */
int hyfi_ecm_update_stats(u_int32_t hash, u_int32_t ecm_serial, u_int64_t num_bytes, u_int64_t num_packets);

#endif /* HYFI_ECM_H_ */
