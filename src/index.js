import { NativeModules, Platform } from 'react-native';
const LINKING_ERROR = `The package '@pagopa/io-react-native-zendesk' doesn't seem to be linked. Make sure: \n\n` +
    Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
    '- You rebuilt the app after installing the package\n' +
    '- You are not using Expo Go\n';
const ReactNativeZendesk = NativeModules.ReactNativeZendesk
    ? NativeModules.ReactNativeZendesk
    : new Proxy({}, {
        get() {
            throw new Error(LINKING_ERROR);
        },
    });
// normal init function when you want to use all of the sdks
export function init(initializationOptins) {
    ReactNativeZendesk.init(initializationOptins);
}
// init function when you just want to use chat sdk
export function initChat(accountKey) {
    ReactNativeZendesk.initChat(accountKey);
}
// function to set primary color code for the chat theme, pass hex code of the color here
export function setPrimaryColor(color) {
    ReactNativeZendesk.setPrimaryColor(color);
}
// function to display help center UI
export function showHelpCenter(chatOptions) {
    ReactNativeZendesk.showHelpCenter(chatOptions);
}
// function to add a ticket custom field
export function addTicketCustomField(key, value) {
    ReactNativeZendesk.addTicketCustomField(key, value);
}
// function to append a new line to the ticket log
export function appendLog(log) {
    ReactNativeZendesk.appendLog(log);
}
// add a new tag to the ticket
export function addTicketTag(tag) {
    ReactNativeZendesk.addTicketTag(tag);
}
// remove custom fields
export function resetCustomFields() {
    ReactNativeZendesk.resetCustomFields();
}
// remove tags
export function resetTags() {
    ReactNativeZendesk.resetTags();
}
// remove log data
export function resetLog() {
    ReactNativeZendesk.resetLog();
}
// iOS only - close the current zendesk view (ticket creation, tickets list) if any
export function dismiss() {
    ReactNativeZendesk.dismiss();
}
// function to open a ticket
export function openTicket(onClose) {
    ReactNativeZendesk.openTicket(onClose);
}
// function to shows all the tickets of the user
export function showTickets(onClose) {
    ReactNativeZendesk.showTickets(onClose);
}
// function that return the number of tickets created by the user
export function hasOpenedTickets() {
    return ReactNativeZendesk.hasOpenedTickets();
}
// function that return the number of unread messages by the user
export function getTotalNewResponses() {
    return ReactNativeZendesk.getTotalNewResponses();
}
// function to set visitor info in chat
export function setVisitorInfo(visitorInfo) {
    ReactNativeZendesk.setVisitorInfo(visitorInfo);
}
// function to register notifications token with zendesk
export function setNotificationToken(token) {
    ReactNativeZendesk.setNotificationToken(token);
}
export function setUserIdentity(identity) {
    ReactNativeZendesk.setUserIdentity(identity);
}
export function resetUserIdentity() {
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
