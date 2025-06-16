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
  (paste-config-file mediagoblin-paste-config-file (default "/etc/mediagoblin/paste.ini")))

(define (mediagoblin-shepherd-service config)
  (list (shepherd-service
         (provision '(mediagoblin))
         (requirement '(user-processes))
         (start #~(make-forkexec-constructor
                   ;; Should be like:
                   ;;
                   ;; ../bin/gmg serve paste.ini
                   ;;
                   ;; assuming that paste.ini already exists on the system
                   ;;
                   ;; TODO: How should you run the one-off `gmg dbupdate` and
                   ;; `gmg adduser` commands?
                   (list
                    #$(file-append mediagoblin "/bin/gmg")
                    ;; TODO: Currently passing through the file path, but what
                    ;; we really need is a reference to the contents.
                    ;;
                    ;; TODO: The `-cf mediagoblin.ini` is currently ignored by
                    ;; the `serve` command because this is really wrapper around
                    ;; paste.
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
