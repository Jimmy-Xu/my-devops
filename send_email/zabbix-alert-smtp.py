#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Zabbix SMTP Alert script (Gmail and SES available).
"""

import sys
import smtplib
from email.MIMEText import MIMEText
from email.Header import Header
from email.Utils import formatdate

from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart


try:
    from settings import (SENDER_EMAIL, SMTP_USERNAME, SMTP_PASSWORD, SMTP_SERVER,
                          SMTP_PORT, SENDER_NAME, SMTP_SSL_TYPE)
except ImportError as e:
    pass

SETTINGS_EXAMPLE = """# settings.py - zabbix-alert-smtp

# Mail Account
SENDER_NAME = u'Zabbix Alert'
SENDER_EMAIL = 'your.account@gmail.com'

# Gmail
SMTP_USERNAME = 'your.account@gmail.com'
SMTP_PASSWORD = 'your mail password'

# Mail Server
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587

# SSL Type ('SMTP_TLS': Gmail, 'SMTP_SSL': SES, None: no SSL)
SMTP_SSL_TYPE = SMTP_TLS

# # Amazon SES
# SMTP_USERNAME = 'Access Key Id'
# SMTP_PASSWORD = 'Secret Access Key'
#
# # Mail Server
# SMTP_SERVER = 'email-smtp.us-east-1.amazonaws.com'
# SMTP_PORT = 587
#
# # SSL Type ('SMTP_TLS': Gmail, 'SMTP_SSL': SES, None: no SSL)
# SMTP_SSL_TYPE = SMTP_SSL
"""

SETTINGS_ERROR = """Create your own settings.py file and edit it.
    $ ./zabbix-alert-smtp.sh example > settings.py
"""

ARGUMENT_ERROR = """requires 3 parameters (recipient, subject, body)
    $ zabbix-alert-smtp.sh recipient subject body
"""

def send_mail(recipient, subject, body, attachments="", encoding='utf-8'):
    session = None
    if attachments == "":
        msg = MIMEText(body, 'plain', encoding)
        msg['Subject'] = Header(subject, encoding)
        msg['From'] = Header(u'"{0}" <{1}>'.format(SENDER_NAME, SENDER_EMAIL), encoding)
        msg['To'] = recipient
        msg['Date'] = formatdate()
    else:
        msg = MIMEMultipart()
        msg['Subject'] = Header(subject, encoding)
        msg['From'] = Header(u'"{0}" <{1}>'.format(SENDER_NAME, SENDER_EMAIL), encoding)
        msg['To'] = recipient
        msg['Date'] = formatdate()

        # This is the textual part:
        part = MIMEText(body)
        msg.attach(part)

        # That is what u see if dont have an email reader:
        msg.preamble = 'Multipart massage.\n'

        attachment_list = attachments.split(",")
        # Loop and print each city name.
        for attachment in attachment_list:
            print "attach file: ", attachment
            # This is the binary part(The Attachment):
            part = MIMEApplication(open(attachment,"rb").read())
            part.add_header('Content-Disposition', 'attachment', filename=attachment+".txt")
            msg.attach(part)

    try:
        if SMTP_SSL_TYPE == 'SMTP_SSL':
            session = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT)
        else:
            session = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
            if SMTP_SSL_TYPE == 'SMTP_TLS':
                session.ehlo()
                session.starttls()
                session.ehlo()
        session.login(SMTP_USERNAME, SMTP_PASSWORD)
        session.sendmail(SENDER_EMAIL, recipient, msg.as_string())
    except Exception as e:
        raise e
    finally:
        # close session
        if session:
            session.quit()

if __name__ == '__main__':
    """
    recipient = sys.argv[1]
    subject = sys.argv[2]
    body = sys.argv[3]
    attachment = sys.argv[4]
    """
    try:
        SENDER_EMAIL
    except:
        print SETTINGS_ERROR
    else:
        if len(sys.argv) == 4:
            send_mail(recipient=sys.argv[1],
                      subject=sys.argv[2],
                      body=sys.argv[3])
        elif len(sys.argv) == 5:
            send_mail(recipient=sys.argv[1],
                      subject=sys.argv[2],
                      body=sys.argv[3],
                      attachments=sys.argv[4])
        elif (len(sys.argv) == 2 and sys.argv[1] == 'example'):
            print SETTINGS_EXAMPLE
        else:
            print ARGUMENT_ERROR
            print sys.exit(1)
