/*****************************************************************************
 * Copyright (C) ZyXEL Communications, Corp.
 * All Rights Reserved.
 *
 * ZyXEL Confidential; Need to Know only.
 * Protected as an unpublished work.
 *
 * The computer program listings, specifications and documentation
 * herein are the property of ZyXEL Communications, Corp. and
 * shall not be reproduced, copied, disclosed, or used in whole or
 * in part for any reason without the prior express written permission of
 * ZyXEL Communications, Corp.
 *****************************************************************************/
/*****************************************************************************
 * Program: GPIO driver for zloader
 *  Author: Chang-Hsing Lee.(changhsing.lee@zyxel.com.tw), 2014/09/04
 *****************************************************************************/
#include <common.h>
#include <zgpio.h>

#if defined(CONFIG_BOARD_IPQ806X_CDP) || defined(CONFIG_BOARD_NBG6816)
  #include "zgpio_ipq806x.c"
#elif defined(CONFIG_BOARD_IPQ40xx_CDP) || defined(CONFIG_BOARD_NBG6617)
  #include "zgpio_ipq40xx.c"
#else
  #error "zgpio driver not implement!"
#endif
