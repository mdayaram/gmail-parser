#!/usr/bin/env python

import mailbox
import sys
import pdb

# pdb.set_trace()

if len(sys.argv) == 1:
    print("ERROR: Please provide a path to an mbox file as the argument.")
    exit(-1)

mb = mailbox.mbox(sys.argv[1])
for m in mb.values():
    print("===================================")
    print("Thread ID: ", m.get_all("X-Gm-Thrid"))
    print("Labels: ", m.get_all("X-Gmail-Labels"))
    print("From: ", m.get_all("From"))
    print("To: ", m.get_all("To"))
    print("Date: ", m.get_all("Date"))
    print("Subject: ", m.get_all("Subject"))
    print("Body:")
    for part in m.walk():
        if part.get_content_type() == "text/plain":
            print(part.get_payload())
        elif part.get_content_type() in ["text/html", "multipart/alternative", "multipart/mixed"]:
            continue
        else:
            print("---")
            print("Attachment: ", part.get_content_type())
            print("Size: ", len(part.get_payload()))
