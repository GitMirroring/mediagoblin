;; Test with:
;; guile -L .../mediagoblin/.guix/modules
;; scheme> (use-modules (mediagoblin services))
(define-module (mediagoblin services)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
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

(define (mediagoblin-shepherd-service config)
  (list (shepherd-service
         (provision '(mediagoblin))
         (requirement '(user-processes))
         (start #~(make-forkexec-constructor
                   ;; Should be like:
                   ;; ../bin/gmg -cf mediagoblin.ini serve paste.ini
                   ;; assuming that the .ini files already exist on the system
                   ;;
                   ;; There's also a one-off `gmg dbupdate` and `gmg adduser`.
                   ;; I'll figure those out later.
                   (list
                    #$(file-append mediagoblin "/bin/gmg")
                    ;; TODO: Currently configuring the file path, but what we really
                    ;; need is the whole file.
                    ;; TODO: Config file is actually specified in paste.ini.
                    ;; "-cf" #$(mediagoblin-config-file config)
                    "serve"
                    #$(mediagoblin-paste-config-file config))
                   #:environment-variables (list "CELERY_ALWAYS_EAGER=true")
                   #:log-file "/var/log/mediagoblin.log"))
         (stop #~(make-kill-destructor))
         (documentation "Run the MediaGoblin media hosting service."))))

(define mediagoblin-service-type
  (service-type
   (name 'mediagoblin)
   (description "Run the MediaGoblin media hosting service.")
   (extensions
    (list (service-extension shepherd-root-service-type
                             mediagoblin-shepherd-service)))
   (default-value (mediagoblin-configuration))))
