# pmvacation

* vacation.pl
  * script to automatically respond to email with predetermined start/start date/time parameters.

* sample-vacation.cfg
  * some ideas on how to setup scheduled OOO responses

To enable this in procmail, reference the vacation.pl script as follows
(adjust to suit).  NOTE: this requires $PMDIR/vacation.txt, which should
have a generic vacation message -- the output from vacation.pl via the
configuration will be prepended to that content.

    PMDIR=$HOME/.procmail
    VACATION=`$PMDIR/bin/vacation.pl`
    MYADDR=frodo@theshire.org
    MYNAME=Frodo Baggins
    NL="
    "

    :0
    * ! VACATION ?? no
    {
	LOG="Checking vacation restricted addresses${NL}"

	:0
	* 1^0 FROMADDR ?? no-?reply@
	* 1^0 FROMADDR ?? do-not-reply@
	* 1^0 FROMADDR ?? donotreply@
	* 1^0 FROMADDR ?? bounceback@
	* 1^0 FROMADDR ?? bounce\+[^@]+@
	{
	    LOG="Resetting VACATION to no due to restricted address${NL}"
	    VACATION=no
	}
    }

    :0
      # Only do this if VACATION is set yes
    * VACATION ?? yes
    {
      LOG="vacation enabled - myaddr is $MYADDR${NL}"

      :0 Whc: vacation.lock
	# Don't reply to mail I send myself
      * ! FROMADDR ?? $MYADDR
	# Don't reply to daemons and mailinglists
      * !^FROM_DAEMON
      * !^FROM_MAILER
	# Don't reply to messages thought to be spam
      * !^X-Spam-Flag: YES
	# Ignore messages from known bulk sources (e.g., mailing list managers)
      * !^Precedence: (bulk|junk)
	# Ignore if discernably in a mailing list
      * !^List-
      * !^(Mailing-List|Approved-By|BestServHost|Resent-(Message-ID|Sender)):
      * !^X-[^:]*-List:
      * !^X-(Sent-To|(Listprocessor|Mailman)-Version):
	# Ignore looped messages
      * !^X-Loop: $MYADDR
	# Add message to cache
      | formail -rD 8192 $PMDIR/vacation.cache

	  :0 ehc    # if the name was not in the cache
	  * ? test -r $PMDIR/vacation.txt
	  | (formail -r \
		     -I"Precedence: junk" \
		     -A"X-Loop: $MYADDR" \
		     -I"From: $MYNAME <$MYADDR>"; \
	     $PMDIR/bin/vacation.pl --preamble; \
	     echo ""; \
	     cat $PMDIR/vacation.txt ) \
	  | $SENDMAIL -oi -t

	  :0 a
	  {
	    LOG="out-of-office reply successfully sent to $FROMADDR from $MYADDR${NL}"
	  }
    }
