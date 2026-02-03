;; Test with:
;; guix build --load-path=.../mediagoblin/.guix/modules mediagoblin
;; or:
;; guile --load-path=.../mediagoblin/.guix/modules
;; scheme> (use-modules (mediagoblin services))
;;
;; Install with:
;; sudo guix system --load-path=.../mediagoblin/.guix/modules reconfigure system.scm
;;
;; Inspect with:
;; sudo herd status mediagoblin-webapp
;; sudo herd status mediagoblin-transcoding
;;
;;
;; Questions for Guix service experts:
;;
;; How do you manage developing on a package that's already in Guix, or one of
;; you channels? How do you make your local definition take precedence?
;;
;; How does the service know what packages to include in context?
;;
;; How do you develop a service so that errors are visible an you can test as
;; you go? Not just by experience/inspection/trial-an-error.
;;
;; What's the fastest way to test a service?

(define-module (mediagoblin services)
  #:use-module (gnu packages admin)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu system shadow)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (mediagoblin packages)
  #:export (mediagoblin-configuration
            mediagoblin-service-type))

(define-record-type* <mediagoblin-configuration>
  mediagoblin-configuration make-mediagoblin-configuration
  mediagoblin-configuration?
  (config-file mediagoblin-config-file (default "/etc/mediagoblin/mediagoblin.ini"))
  (paste-config-file mediagoblin-paste-config-file (default "/etc/mediagoblin/paste.ini")))

;; TODO: I saw "least-authority-wrapper" used in other services. Not sure if it's
;; necessary here.
;;
;; TODO: Move data directory to /var. To work around giving both you (the developer) and the "mediagoblin" user the relevant file permissions, I run:
;; sudo chown -R mediagoblin:mediagoblin .../mediagoblin
;; sudo find .../mediagoblin -type d -exec chmod 775 {} \;
;; sudo find .../mediagoblin -type f -exec chmod 664 {} \;
(define %mediagoblin-accounts
  (list (user-account
         (name "mediagoblin")
         (group "mediagoblin")
         (system? #t)
         (comment "MediaGoblin daemon user")
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))
        (user-group
         (name "mediagoblin")
         (system? #t))))

(define (mediagoblin-activation config)
  #~(begin (system*
            #$(file-append mediagoblin "/bin/gmg")
            "-cf" #$(mediagoblin-config-file config)
            "dbupdate")))

(define (mediagoblin-shepherd-service config)
  (list (shepherd-service
         (provision '(mediagoblin-webapp))
         (requirement '(user-processes))
         (start #~(make-forkexec-constructor
                   ;; TODO: Consider using our standard `../bin/paster serve
                   ;; paste.ini` and `../bin/celery worker`, rather than the
                   ;; experimental `gmg serve` and `gmg celery`. This would be
                   ;; more in-line with our recommended deployment approach. One
                   ;; current problem with our experimental commands is that
                   ;; they ignore the `gmg -cf mediagoblin.ini` config, which
                   ;; would be confusing for users.
                   ;;
                   ;; TODO: How should we support running of `gmg adduser`?
                   (list
                    #$(file-append mediagoblin "/bin/gmg")
                    "serve"
                    #$(local-file (mediagoblin-paste-config-file config)))
                   #:user "mediagoblin" #:group "mediagoblin"
                   #:log-file "/var/log/mediagoblin.log"))
         (stop #~(make-kill-destructor))
         (documentation "Run the MediaGoblin media hosting service web application."))
        (shepherd-service
         (provision '(mediagoblin-transcoding))
         (requirement '(user-processes))
         (start #~(make-forkexec-constructor
                   (list #$(file-append mediagoblin "/bin/gmg") "celery")
                   ;; TODO: MediaGoblin currently expects a Redis instance
                   ;; running on the standard port. (RabbitMQ is another option,
                   ;; but it's not packaged for Guix.)
                   ;;
                   ;; TODO: You must manually configure 'BROKER_URL = "redis://"' in
                   ;; mediagoblin.ini which is a little clumsy.
                   #:environment-variables
                   (list
                    ;; This works, but only applies to Celery, not the web app above.
                    ;; "CELERY_BROKER_URL=redis://"
                    (string-append
                     "MEDIAGOBLIN_CONFIG=" #$(local-file (mediagoblin-config-file config))))
                   #:user "mediagoblin" #:group "mediagoblin"
                   #:log-file "/var/log/mediagoblin-celery.log"))
         (stop #~(make-kill-destructor))
         (documentation "Run the MediaGoblin media transcoding service."))))

(define mediagoblin-service-type
  (service-type
   (name 'mediagoblin)
   (description "Run the MediaGoblin media hosting service.")
   (extensions
    (list (service-extension account-service-type
                             (const %mediagoblin-accounts))
          (service-extension shepherd-root-service-type
                             mediagoblin-shepherd-service)
          (service-extension activation-service-type mediagoblin-activation)))
   (default-value (mediagoblin-configuration))))
