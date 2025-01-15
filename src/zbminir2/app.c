/***************************************************************************//**
 * @file app.c
 * @brief Callbacks implementation and application specific code.
 *******************************************************************************
 * # License
 * <b>Copyright 2021 Silicon Laboratories Inc. www.silabs.com</b>
 *******************************************************************************
 *
 * The licensor of this software is Silicon Laboratories Inc. Your use of this
 * software is governed by the terms of Silicon Labs Master Software License
 * Agreement (MSLA) available at
 * www.silabs.com/about-us/legal/master-software-license-agreement. This
 * software is distributed to you in Source Code format and is governed by the
 * sections of the MSLA applicable to Source Code.
 *
 ******************************************************************************/

#include "app/framework/include/af.h"
#ifdef SL_COMPONENT_CATALOG_PRESENT
#include "sl_component_catalog.h"
#endif

#include "zigbee_sleep_config.h"
#include "network-steering.h"

#ifdef SL_CATALOG_ZIGBEE_ZLL_COMMISSIONING_COMMON_PRESENT
#include "zll-commissioning.h"
#endif //SL_CATALOG_ZIGBEE_ZLL_COMMISSIONING_COMMON_PRESENT

#if defined(SL_CATALOG_LED0_PRESENT)
#include "sl_led.h"
#include "sl_simple_led_instances.h"
#define led_turn_on(led) sl_led_turn_on(led)
#define led_turn_off(led) sl_led_turn_off(led)
#define led_toggle(led) sl_led_toggle(led)
#define COMMISSIONING_STATUS_LED (&sl_led_led0)
#define ON_OFF_LIGHT_LED         (&sl_led_relay)
#else // !SL_CATALOG_LED0_PRESENT
#define led_turn_on(led)
#define led_turn_off(led)
#define led_toggle(led)
#endif // SL_CATALOG_LED0_PRESENT

#define LED_BLINK_PERIOD_MS      2000
#define LIGHT_ENDPOINT           1
#define RESET_TIMEOUT_MS         1000
#define RESET_NUM_TOGGLES        5

static sl_zigbee_af_event_t commissioning_event;
static sl_zigbee_af_event_t switch_event;

#include "sl_simple_button.h"
#include "sl_simple_button_instances.h"

uint64_t last_toggle = 0;
int num_toggles = 0;

void rejoin_logic()
{
    uint64_t tick, dt;

    tick = sl_sleeptimer_get_tick_count64();
    sl_sleeptimer_tick64_to_ms(tick - last_toggle, &dt);

    if(dt > RESET_TIMEOUT_MS) {
      num_toggles = 0;
    } else {
      num_toggles++;
    }

    if(num_toggles > RESET_NUM_TOGGLES) {
      num_toggles = 0;
      sl_zigbee_app_debug_println("%s: trigger factory reset!", __func__);
      sl_zigbee_af_event_set_active(&commissioning_event);
    }

    last_toggle = tick;

    sl_zigbee_app_debug_println("%s: num_toggles=%d", __func__, num_toggles);
}

//---------------
// Event handlers

static void switch_event_handler(sl_zigbee_af_event_t *event)
{
  sl_status_t status;
  sl_button_state_t state;
  
  state = sl_button_get_state(&sl_button_btn_switch);

  // count button releases for rejoin logic
  if(state == SL_SIMPLE_BUTTON_RELEASED) {
    rejoin_logic();
  }

  if(sl_zigbee_af_network_state() == SL_ZIGBEE_JOINED_NETWORK) {
    
    if(state == SL_SIMPLE_BUTTON_PRESSED) {
      //sl_zigbee_af_fill_command_on_off_cluster_on();
      //sl_zigbee_af_fill_command_level_control_cluster_move_to_level_with_on_off(0, 0);
    } else {
      //sl_zigbee_af_fill_command_on_off_cluster_off();
      //sl_zigbee_af_fill_command_level_control_cluster_move_to_level_with_on_off(255, 0);
    }

    sl_zigbee_af_fill_command_on_off_cluster_toggle();

    sl_zigbee_af_set_command_endpoints(LIGHT_ENDPOINT, 0);

    status = sl_zigbee_af_send_command_unicast_to_bindings();
    sl_zigbee_app_debug_println("%s: 0x%X", "Send to bindings", status);
  }
}

static void commissioning_event_handler(sl_zigbee_af_event_t *event)
{
  if(sl_button_get_state(&sl_button_btn_button) == SL_SIMPLE_BUTTON_RELEASED) {
    if(sl_zigbee_af_network_state() == SL_ZIGBEE_JOINED_NETWORK) {
      sl_zigbee_app_debug_println("%s: leave network", __func__);
      sl_zigbee_leave_network(SL_ZIGBEE_LEAVE_NWK_WITH_NO_OPTION);
    } else {
      sl_zigbee_app_debug_println("%s: network_steering_start", __func__);
      sl_zigbee_af_network_steering_start();
    }
  }
}

//----------------------
// Implemented Callbacks

/** @brief Stack Status
 *
 * This function is called by the application framework from the stack status
 * handler.  This callbacks provides applications an opportunity to be notified
 * of changes to the stack status and take appropriate action. The framework
 * will always process the stack status after the callback returns.
 */
void sl_zigbee_af_stack_status_cb(sl_status_t status)
{
  // Note, the ZLL state is automatically updated by the stack and the plugin.
  if (status == SL_STATUS_NETWORK_DOWN) {
    led_turn_off(COMMISSIONING_STATUS_LED);
    sl_zigbee_app_debug_println("sl_zigbee_af_stack_status_cb: SL_STATUS_NETWORK_DOWN");

    // XXX: maybe this isn't always desired?
    sl_zigbee_af_event_set_active(&commissioning_event);
  } else if (status == SL_STATUS_NETWORK_UP) {
    led_turn_on(COMMISSIONING_STATUS_LED);
  }
}

/** @brief Init
 * Application init function
 */
void sl_zigbee_af_main_init_cb(void)
{
  sl_zigbee_af_isr_event_init(&commissioning_event, commissioning_event_handler);
  sl_zigbee_af_isr_event_init(&switch_event, switch_event_handler);
}

/** @brief Complete network steering.
 *
 * This callback is fired when the Network Steering plugin is complete.
 *
 * @param status On success this will be set to SL_STATUS_OK to indicate a
 * network was joined successfully. On failure this will be the status code of
 * the last join or scan attempt.
 *
 * @param totalBeacons The total number of 802.15.4 beacons that were heard,
 * including beacons from different devices with the same PAN ID.
 *
 * @param joinAttempts The number of join attempts that were made to get onto
 * an open Zigbee network.
 *
 * @param finalState The finishing state of the network steering process. From
 * this, one is able to tell on which channel mask and with which key the
 * process was complete.
 */
void sl_zigbee_af_network_steering_complete_cb(sl_status_t status,
                                               uint8_t totalBeacons,
                                               uint8_t joinAttempts,
                                               uint8_t finalState)
{
  sl_zigbee_app_debug_println("Join network complete: 0x%X", status);
}

/** @brief Post Attribute Change
 *
 * This function is called by the application framework after it changes an
 * attribute value. The value passed into this callback is the value to which
 * the attribute was set by the framework.
 */
void sl_zigbee_af_post_attribute_change_cb(uint8_t endpoint,
                                           sl_zigbee_af_cluster_id_t clusterId,
                                           sl_zigbee_af_attribute_id_t attributeId,
                                           uint8_t mask,
                                           uint16_t manufacturerCode,
                                           uint8_t type,
                                           uint8_t size,
                                           uint8_t* value)
{
  if (clusterId == ZCL_ON_OFF_CLUSTER_ID
      && attributeId == ZCL_ON_OFF_ATTRIBUTE_ID
      && mask == CLUSTER_MASK_SERVER) {
    bool onOff;
    if (sl_zigbee_af_read_server_attribute(endpoint,
                                           ZCL_ON_OFF_CLUSTER_ID,
                                           ZCL_ON_OFF_ATTRIBUTE_ID,
                                           (uint8_t *)&onOff,
                                           sizeof(onOff))
        == SL_ZIGBEE_ZCL_STATUS_SUCCESS) {
      if (onOff) {
        led_turn_on(ON_OFF_LIGHT_LED);
      } else {
        led_turn_off(ON_OFF_LIGHT_LED);
      }
    }
  }
}

/** @brief On/off Cluster Server Post Init
 *
 * Following resolution of the On/Off state at startup for this endpoint, perform any
 * additional initialization needed; e.g., synchronize hardware state.
 *
 * @param endpoint Endpoint that is being initialized
 */
void sl_zigbee_af_on_off_cluster_server_post_init_cb(uint8_t endpoint)
{
  // At startup, trigger a read of the attribute and possibly a toggle of the
  // LED to make sure they are always in sync.
  sl_zigbee_af_post_attribute_change_cb(endpoint,
                                        ZCL_ON_OFF_CLUSTER_ID,
                                        ZCL_ON_OFF_ATTRIBUTE_ID,
                                        CLUSTER_MASK_SERVER,
                                        0,
                                        0,
                                        0,
                                        NULL);
}

/** @brief
 *
 * Application framework equivalent of ::sl_zigbee_radio_needs_calibrating_handler
 */
void sl_zigbee_af_radio_needs_calibrating_cb(void)
{
  #ifndef EZSP_HOST
  sl_mac_calibrate_current_channel();
  #endif
}

void sl_button_on_change(const sl_button_t *handle)
{
  int pressed;

  pressed = sl_button_get_state(handle) == SL_SIMPLE_BUTTON_PRESSED;

  if(handle == &sl_button_btn_button) {
      sl_zigbee_app_debug_println("%s: button %d\n", __func__, pressed);

      if(pressed == 0) {
        sl_zigbee_af_event_set_active(&commissioning_event);
      }
  } else if(handle == &sl_button_btn_switch) {
      sl_zigbee_app_debug_println("%s: switch %d\n", __func__, pressed);
      sl_zigbee_af_event_set_active(&switch_event);
  }
}