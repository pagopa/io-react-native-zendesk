declare module 'io-react-native-zendesk' {

  // function to display chat box
  export function startChat(chatOptions: ChatOptions): void;

  // normal init function when you want to use all of the sdks
  export function init(initializationOptins: InitOptions): void;

  // init function when you just want to use chat sdk
  export function initChat(accountKey: string): void;

  // function to set primary color code for the chat theme, pass hex code of the color here
  export function setPrimaryColor(color: string): void;

  // function to display help center UI
  export function showHelpCenter(chatOptions: ChatOptions): void;

  // function to add a ticket custom field
  export function addTicketCustomField(key: string, value: string): void;

  // function to append a new line to the ticket log
  export function appendLog(log: string)

  // add a new tag to the ticket
  export function addTicketTag(tag: string)

  // remove log data and custom fields
  export function reset(): void;

  // close the current zendesk view (ticket creation, tickets list) if any
  export function dismiss(): void;

  // function to open a ticket
  export function openTicket(): void;

  // function to shows all the tickets of the user
  export function showTickets(): void;

  // function that return the number of tickets created by the user
  export function hasOpenedTickets(): Promise<number>;

  // function that return the number of unread messages by the user
  export function getTotalNewResponses(): Promise<number>;

  // function to set visitor info in chat
  export function setVisitorInfo(visitorInfo: UserInfo): void;

  // function to register notifications token with zendesk
  export function setNotificationToken(token: string): void;

  export function setUserIdentity(identity: JwtIdentity | AnonymousIdentity): void;

  export function resetUserIdentity(): void;

  interface ChatOptions extends UserInfo {
    botName?: string
    // boolean value if you want just chat sdk or want to use all the sdk like support, answer bot and chat
    // true value means just chat sdk
    chatOnly?: boolean
    // hex code color to set on chat
    color?: string
    /* help center specific props only */
    // sent in help center function only to show help center with/without chat
    withChat?: boolean
    // to enable/disable ticket creation in help center
    disableTicketCreation?: boolean
  }

  interface InitOptions {
    // chat key of zendesk account to init chat
    key: string,
    // appId of your zendesk account
    appId: string,
    // clientId of your zendesk account
    clientId: string,
    // support url of zendesk account
    url: string,
    // id of the log custom field
    logId: string
  }

  interface UserInfo extends AnonymousIdentity{
    // user's phone
    phone?: number
    // department to redirect the chat
    department?: string
    // tags for chat
    tags?: Array<string>
  }

  interface JwtIdentity {
    token: string
  }

  interface AnonymousIdentity {
    // user's name
    name?: string
    // user's email
    email?: string
  }

}
