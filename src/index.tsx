import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package '@pagopa/io-react-native-zendesk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const ReactNativeZendesk = NativeModules.ReactNativeZendesk
  ? NativeModules.ReactNativeZendesk
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );
export interface ChatOptions extends UserInfo {
  botName?: string;
  // boolean value if you want just chat sdk or want to use all the sdk like support, answer bot and chat
  // true value means just chat sdk
  chatOnly?: boolean;
  // hex code color to set on chat
  color?: string;
  /* help center specific props only */
  // sent in help center function only to show help center with/without chat
  withChat?: boolean;
  // to enable/disable ticket creation in help center
  disableTicketCreation?: boolean;
}

export interface InitOptions {
  // chat key of zendesk account to init chat
  key: string;
  // appId of your zendesk account
  appId: string;
  // clientId of your zendesk account
  clientId: string;
  // support url of zendesk account
  url: string;
  // id of the log custom field
  logId: string;
}

interface UserInfo extends AnonymousIdentity {
  // user's phone
  phone?: number;
  // department to redirect the chat
  department?: string;
  // tags for chat
  tags?: Array<string>;
}

export interface JwtIdentity {
  token: string;
}

export interface AnonymousIdentity {
  // user's name
  name?: string;
  // user's email
  email?: string;
}

// normal init function when you want to use all of the sdks
export function init(initializationOptins: InitOptions): void {
  ReactNativeZendesk.init(initializationOptins);
}

// init function when you just want to use chat sdk
export function initChat(accountKey: string): void {
  ReactNativeZendesk.initChat(accountKey);
}

// function to set primary color code for the chat theme, pass hex code of the color here
export function setPrimaryColor(color: string): void {
  ReactNativeZendesk.setPrimaryColor(color);
}

// function to display help center UI
export function showHelpCenter(chatOptions: ChatOptions): void {
  ReactNativeZendesk.showHelpCenter(chatOptions);
}

// function to add a ticket custom field
export function addTicketCustomField(key: string, value: string): void {
  ReactNativeZendesk.addTicketCustomField(key, value);
}

// function to append a new line to the ticket log
export function appendLog(log: string) {
  ReactNativeZendesk.appendLog(log);
}

// add a new tag to the ticket
export function addTicketTag(tag: string) {
  ReactNativeZendesk.addTicketTag(tag);
}

// remove custom fields
export function resetCustomFields(): void {
  ReactNativeZendesk.resetCustomFields();
}

// remove tags
export function resetTags(): void {
  ReactNativeZendesk.resetTags();
}

// remove log data
export function resetLog(): void {
  ReactNativeZendesk.resetLog();
}

// iOS only - close the current zendesk view (ticket creation, tickets list) if any
export function dismiss(): void {
  ReactNativeZendesk.dismiss();
}

// function to open a ticket
export function openTicket(onClose: () => void): void {
  ReactNativeZendesk.openTicket(onClose);
}

// function to shows all the tickets of the user
export function showTickets(onClose: () => void): void {
  ReactNativeZendesk.showTickets(onClose);
}

// function that return the number of tickets created by the user
export function hasOpenedTickets(): Promise<number> {
  return ReactNativeZendesk.hasOpenedTickets();
}

// function that return the number of unread messages by the user
export function getTotalNewResponses(): Promise<number> {
  return ReactNativeZendesk.getTotalNewResponses();
}

// function to set visitor info in chat
export function setVisitorInfo(visitorInfo: UserInfo): void {
  ReactNativeZendesk.setVisitorInfo(visitorInfo);
}

// function to register notifications token with zendesk
export function setNotificationToken(token: string): void {
  ReactNativeZendesk.setNotificationToken(token);
}

export function setUserIdentity(
  identity: JwtIdentity | AnonymousIdentity
): void {
  ReactNativeZendesk.setUserIdentity(identity);
}

export function resetUserIdentity(): void {
  ReactNativeZendesk.resetUserIdentity();
}

class IoReactNativeZendesk {
  static init = init;
  static initChat = initChat;
  static setPrimaryColor = setPrimaryColor;
  static showHelpCenter = showHelpCenter;
  static addTicketCustomField = addTicketCustomField;
  static appendLog = appendLog;
  static addTicketTag = addTicketTag;
  static resetCustomFields = resetCustomFields;
  static resetTags = resetTags;
  static resetLog = resetLog;
  static dismiss = dismiss;
  static openTicket = openTicket;
  static showTickets = showTickets;
  static hasOpenedTickets = hasOpenedTickets;
  static getTotalNewResponses = getTotalNewResponses;
  static setVisitorInfo = setVisitorInfo;
  static setNotificationToken = setNotificationToken;
  static setUserIdentity = setUserIdentity;
  static resetUserIdentity = resetUserIdentity;
}

export default IoReactNativeZendesk;
