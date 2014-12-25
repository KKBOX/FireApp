== 0.9.6 (pending)

* match X.509 extension short-comings of the Java API in order to align with MRI
* improve cert.extension's value - *extendedKeyUsage* was not returned correctly
* make sure ASN1::ObjectId.new(...).ln and ASN1::ObjectId.new(...).sn are correct!
* better working to_der conversion esp. with constructives (indefinite lengths)
* improve our ASN1 decoding for better MRI compatibility
* avoiding Krypt gem dependency completely (was used for OpenSSL::PKCS5)
* cleanup OpenSSL::Digest internals - make sure block_length works for more
* OpenSSL deprecated_warning_flag and check_func API compatibility stubs
* do not force loading of jar-dependencies + possibly respect jars skipped
* X509::Name.to_a compatibility - MRI seems to never return "UNDEF"
 experimental support for passing down "real" Java JCE cipher names
* rewriten Cipher internals - now faster, slimmer and more compatible than ever!
* rebuilt our global ASN1Registry and refactored it (back) internally to use string oids
* report OpenSSL::VERSION **1.1.0** since 1.9.3
* fill RaiseException's cause whenever we use a factory passing down a Throwable
* allow X509::Revoked.serial= to receive an integer
* make sure X509::CRL's to_text representation si (fully) MRI compatible
* handle authority key-id unwrapping correctly in X509::Extension#value
* long time coming - OpenSSL::X509::CRL support for loading revoked entries (#5)
* Reflect Java cacert location in DEFAULT_CERT_* constants (jruby/jruby#1953)
* X509::Certificate.new MRI compatibility + make sure inspect works the same
* BN.inspect() and make sure BN.new(0) works just fine (both as in MRI)
* X509::CRL instantiation compatibility with MRI
* inspect() X509::Certificate an X509::CRL just like MRI does
* handle OpenSSL::X509::Store.add error messages correctly (fix based on #6)
* update to using BC 1.49 by default (still compatible with older versions)
* implement X509::StoreContext#current_crl method
* support X509::StoreContext cleanup and error_depth instance methods
* support disabling of warnings using system property -Djruby.openssl.warn
* Throw error when chain certs are *not* OpenSSL::X509::Certificate (#3)
* avoid using JRuby IO APIs (will likely not work in 9k)
* make 'jopenssl/load' also work on jruby-1.6.8 mode 1.9

== 0.9.5

MASSIVE internal "rewrite" to avoid depending on a registered (BC) security
provider. This releases restores compatibility with BC version 1.47 while being
compatible with newer bouncy-castle jars as well (1.48, 1.49 and 1.50).

* handle SSLErrorWaitReadable/Writable as SSLErrors on Ruby 1.8 and 1.9 mode
* Treat SSL NOT_HANDSHAKING as FINISHED
* only add DER.TRUE when encoding X.509 extension when non-critical
* do not der encode non-critical flag in X509::Extension (jruby/jruby#389)
* SSLContext internals + support `SSLContext::METHODS` correctly (jruby/jruby#1596)
* correct visibility of initialize* and respond_to_missing? methods
* fix spinning indefinitely on partial TLS record (jruby/jruby#1280)
* Support file input for PKey::RSA.new
* fix bug https://github.com/jruby/jruby/issues/1156
* openssl: add handling for base 0 to new and to_s

== 0.9.4

* Fix compatibility wiht Bouncy Castle 1.49.

== 0.9.3

* Allow options passed to nonblock methods (not impl'ed yet)
* Make ClassIndex into an enum, to prevent issues like jruby/jruby#1004


== ...


== 0.7.7

This release includes bug fixes.

* JRUBY-6622: Support loading encrypted RSA key with PBES2
* JRUBY-4326: Confusing (and late) OpenSSL error message
* JRUBY-6579: Avoid ClassCastException for public key loading
* JRUBY-6515: sending UTF-8 data over SSL can hang with openssl
* Update tests to sync with CRuby ruby_1_9_3

== 0.7.6

This release includes initial implementation of PKCS12 by Owen Ou.

* JRUBY-5066: Implement OpenSSL::PKCS12 (only for simple case)
* JRUBY-6385: Assertion failure with -J-ea

== 0.7.5

This release improved 1.9 mode support with help of
Duncan Mak <duncan@earthaid.net>.  Now jruby-ossl gem includes both 1.8 and 1.9
libraries and part of features should work fine on 1.9 mode, too.

* JRUBY-6270: Wrong keyUsage check for SSL server
* JRUBY-6260: OpenSSL::ASN1::Integer#value incompatibility
* JRUBY-6044: Improve Ecrypted RSA/DSA pem support
* JRUBY-5972: Allow to load/dump empty PKCS7 data
* JRUBY-5834: Fix X509Name handling; X509Name RDN can include multiple elements
* JRUBY-5362: Improved 1.9 support
* JRUBY-4992: Warn if loaded by non JRuby interpreter

== 0.7.4

* JRUBY-5519: Avoid String encoding dependency in DER loading. PEM loading
  failed on JRuby 1.6.x. Fixed.
* JRUBY-5510: Add debug information to released jar
* JRUBY-5478: Update bouncycastle jars to the latest version. (1.46)

== 0.7.3

* JRUBY-5200: Net::IMAP + SSL(imaps) login could hang. Fixed.
* JRUBY-5253: Allow to load the certificate file which includes private
  key for activemarchant compatibility.
* JRUBY-5267: Added SSL socket error-checks to avoid busy loop under an
  unknown condition.
* JRUBY-5316: Improvements for J9's IBMJCE support. Now all testcases
  pass on J9 JDK 6.

== 0.7.2

* JRUBY-5126: Ignore Cipher#reset and Cipher#iv= when it's a stream
  cipher (Net::SSH compatibility)
* JRUBY-5125: let Cipher#name for 'rc4' to be 'RC4' (Net::SSH
  compatibility)
* JRUBY-5096: Fixed inconsistent Certificate verification behavior
* JRUBY-5060: Avoid NPE from to_pem for empty X509 Objects
* JRUBY-5059: SSLSocket ignores Timeout (Fixed)
* JRUBY-4965: implemented OpenSSL::Config
* JRUBY-5023: make Certificate#signature_algorithm return correct algo
  name; "sha1WithRSAEncryption" instead of "SHA1"
* JRUBY-5024: let HMAC.new accept a String as a digest name
* JRUBY-5018: SSLSocket holds selectors, keys, preventing quick
  cleanup of resources when dereferenced

== 0.7.1

NOTE: Now BouncyCastle jars has moved out to its own gem "bouncy-castle-java"
http://rubygems.org/gems/bouncy-castle-java. You don't need to care about it
because "jruby-openssl" gem depends on it from now on.

* JRUBY-4826 net/https client possibly raises "rbuf_fill': End of file
  reached (EOFError)" for HTTP chunked read.

* JRUBY-4900: Set proper String to OpenSSL::OPENSSL_VERSION. Make sure
  it's not an OpenSSL artifact: "OpenSSL 0.9.8b 04 May 2006
  (JRuby-OpenSSL fake)" -> "jruby-ossl 0.7.1"
* JRUBY-4975: Moving BouncyCastle jars out to its own gem.

== 0.7

* Follow MRI 1.8.7 openssl API changes
* Fixes so that jruby-openssl can run on appengine
* Many bug and compatibility fixes, see below.
* This is the last release that will be compatible with JRuby 1.4.x.
* Compatibility issues
 - JRUBY-4342: Follow ruby-openssl of CRuby 1.8.7.
 - JRUBY-4346: Sync tests with tests for ruby-openssl of CRuby 1.8.7.
 - JRUBY-4444: OpenSSL crash running RubyGems tests
 - JRUBY-4075: Net::SSH gives OpenSSL::Cipher::CipherError "No message
   available"
 - JRUBY-4076: Net::SSH padding error using 3des-cbc on Solaris
 - JRUBY-4541: jruby-openssl doesn't load on App Engine.
 - JRUBY-4077: Net::SSH "all authorization methods failed" Solaris -> Solaris
 - JRUBY-4535: Issues with the BouncyCastle provider
 - JRUBY-4510: JRuby-OpenSSL crashes when JCE fails a initialise bcprov
 - JRUBY-4343: Update BouncyCastle jar to upstream version; jdk14-139 ->
   jdk15-144
 Cipher issues
 - JRUBY-4012: Initialization vector length handled differently than in MRI
   (longer IV sequence are trimmed to fit the required)
 - JRUBY-4473: Implemented DSA key generation
 - JRUBY-4472: Cipher does not support RC4 and CAST
 - JRUBY-4577: InvalidParameterException 'Wrong keysize: must be equal to 112 or
   168' for DES3 + SunJCE
 SSL and X.509(PKIX) issues
 - JRUBY-4384: TCP socket connection causes busy loop of SSL server
 - JRUBY-4370: Implement SSLContext#ciphers
 - JRUBY-4688: SSLContext#ciphers does not accept 'DEFAULT'
 - JRUBY-4357: SSLContext#{setup,ssl_version=} are not implemented
 - JRUBY-4397: SSLContext#extra_chain_cert and SSLContext#client_ca
 - JRUBY-4684: SSLContext#verify_depth is ignored
 - JRUBY-4398: SSLContext#options does not affect to SSL sessions
 - JRUBY-4360: Implement SSLSocket#verify_result and dependents
 - JRUBY-3829: SSLSocket#read should clear given buffer before concatenating
   (ByteBuffer.java:328:in `allocate': java.lang.IllegalArgumentException when
   returning SOAP queries over a certain size)
 - JRUBY-4686: SSLSocket can drop last chunk of data just before inbound channel
   close
 - JRUBY-4369: X509Store#verify_callback is not called
 - JRUBY-4409: OpenSSL::X509::Store#add_file corrupts when it includes
   certificates which have the same subject (problem with
   ruby-openid-apps-discovery (github jruby-openssl issue #2))
 - JRUBY-4333: PKCS#8 formatted privkey read
 - JRUBY-4454: Loading Key file as a Certificate causes NPE
 - JRUBY-4455: calling X509::Certificate#sign for the Certificate initialized
   from PEM causes IllegalStateException
 PKCS#7 issues
 - JRUBY-4379: PKCS7#sign failed for DES3 cipher algorithm
 - JRUBY-4428: Allow to use DES-EDE3-CBC in PKCS#7 w/o the Policy Files (rake
   test doesn't finish on JDK5 w/o policy files update)
 Misc
 - JRUBY-4574: jruby-openssl deprecation warning cleanup
 - JRUBY-4591: jruby-1.4 support

== 0.6

* This is a recommended upgrade to jruby-openssl. A security problem
  involving peer certificate verification was found where failed
  verification silently did nothing, making affected applications
  vulnerable to attackers. Attackers could lead a client application
  to believe that a secure connection to a rogue SSL server is
  legitimate. Attackers could also penetrate client-validated SSL
  server applications with a dummy certificate. Your application would
  be vulnerable if you're using the 'net/https' library with
  OpenSSL::SSL::VERIFY_PEER mode and any version of jruby-openssl
  prior to 0.6. Thanks to NaHi (NAKAMURA Hiroshi) for finding the
  problem and providing the fix. See
  http://www.jruby.org/2009/12/07/vulnerability-in-jruby-openssl.html
  for details.
* This release addresses CVE-2009-4123 which was reserved for the
  above vulnerability.
* Many fixes from NaHi, including issues related to certificate
  verification and certificate store purpose verification.
  - implement OpenSSL::X509::Store#set_default_paths
  - MRI compat. fix: OpenSSL::X509::Store#add_file
  - Fix nsCertType handling.
  - Fix Cipher#key_len for DES-EDE3: 16 should be 24.
  - Modified test expectations around Cipher#final.
* Public keys are lazily instantiated when the
  X509::Certificate#public_key method is called (Dave Garcia)

== 0.5.2

Multiple bugs fixed:

* JRUBY-3895	Could not verify server signature with net-ssh against Cygwin
* JRUBY-3864	jruby-openssl depends on Base64Coder from JvYAMLb
* JRUBY-3790	JRuby-OpenSSL test_post_connection_check is not passing
* JRUBY-3767	OpenSSL ssl implementation doesn't support client auth
* JRUBY-3673	jRuby-OpenSSL does not properly load certificate authority file

== 0.5.1

* Multiple fixes by Brice Figureau to get net/ssh working. Requires JRuby 1.3.1
  to be 100%
* Fix by Frederic Jean for a character-decoding issue for some certificates

== 0.5

* Fixed JRUBY-3614: Unsupported HMAC algorithm (HMACSHA-256)
* Fixed JRUBY-3570: ActiveMerchant's AuthorizeNet Gateway throws OpenSSL Cert
  Validation Error, when there should be no error
* Fixed JRUBY-3557 Class cast exception in PKeyRSA.java
* Fixed JRUBY-3468 X.509 certificates: subjectKeyIdentifier corrupted
* Fixed JRUBY-3285 Unsupported HMAC algorithm (HMACSHA1) error when generating
  digest
* Misc code cleanup

== 0.2

* Enable remaining tests; fix a nil string issue in SSLSocket.sysread
  (JRUBY-1888)
* Fix socket buffering issue by setting socket IO sync = true
* Fix bad file descriptor issue caused by unnecessary close (JRUBY-2152)
* Fix AES key length (JRUBY-2187)
* Fix cipher initialization (JRUBY-1100)
* Now, only compatible with JRuby 1.1

== 0.1.1

* Fixed blocker issue preventing HTTPS/SSL from working (JRUBY-1222)

== 0.1

* PLEASE NOTE: This release is not compatible with JRuby releases earlier than
  1.0.3 or 1.1b2. If you must use JRuby 1.0.2 or earlier, please install the
  0.6 release.
* Release coincides with JRuby 1.0.3 and JRuby 1.1b2 releases
* Simultaneous support for JRuby trunk and 1.0 branch
* Start of support for OpenSSL::BN

== 0.0.5 and prior

* Initial versions with maintenance updates
