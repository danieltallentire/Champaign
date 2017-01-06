// @flow
import $ from '../../util/PubSub';

import type { FundraiserAction } from './reducer';

export function changeAmount(payload: ?number): FundraiserAction {
  $.publish('fundraiser:change_amount', [payload]);
  return { type: 'change_amount', payload };
}

export function changeCurrency(payload: string): FundraiserAction {
  $.publish('fundraiser:change_currency', [payload]);
  return { type: 'change_currency', payload };
}

export function changeStep(payload: number): FundraiserAction {
  // we put it in a timeout because otherwise the event is fired before the step has switched
  window.setTimeout(() => { $.publish('fundraiser:change_step', [payload]); }, 100);
  return { type: 'change_step', payload };
}

export function updateForm(payload: Object): FundraiserAction {
  return { type: 'update_form', payload };
}

export function setRecurring(payload: boolean = false): FundraiserAction {
  return { type: 'set_recurring', payload };
}

export function setStoreInVault(payload: boolean = false): FundraiserAction {
  return { type: 'set_store_in_vault', payload };
}

export function setPaymentType(payload: ?string = null): FundraiserAction {
  return { type: 'set_payment_type', payload };
}
