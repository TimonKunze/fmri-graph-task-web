/**
 * By calling this function you can send a message to a 
 * specific user via telegram
 * @param {String} the text to send
 *
*/
export function sendMessage(text) {
  let tg = {
      // Your bot's token that got from @BotFather
      token: "7087198601:AAFYd0U-IbCKAnzc-m9Rn_8ebW80eZm6as0",
      // The user's(that you want to send a message) telegram chat id
      chat_id: "292107138"
  }
  const url = `https://api.telegram.org/bot${tg.token}/sendMessage?chat_id=${tg.chat_id}&text=${text}`; // The url to request
  const xht = new XMLHttpRequest();
  xht.open("GET", url);
  xht.send();
}
