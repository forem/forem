require "fileinto";
require "imap4flags";

if header :is "X-Spam" "Yes" {
    fileinto "Junk";
    setflag "\\seen";
    stop;
}

/* Other messages get filed into Inbox or to user's scripts */
