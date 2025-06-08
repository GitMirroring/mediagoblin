(define-module (service)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:export (mediagoblin-service-type))

(define (mediagoblin-shepherd-service config)
  (list (shepherd-service
         (provision '(mediagoblin))
         (start #~(make-forkexec-constructor
                   (list
                    #$(file-append package "/bin/gmg")
                    "serve"
                    ;; needs paste.ini config file
                    )))
         (stop #~(make-kill-destructor))
         (documentation "mediagoblin"))))

(define mediagoblin-service-type
  (service-type
   (name 'mediagoblin)
   (description "Run the MediaGoblin media hosting service.")
   (extensions
    (list (service-extension shepherd-root-service-type
                             mediagoblin-shepherd-service)))))
