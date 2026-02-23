;; ============================================================
;; Contract: verdict-core.clar
;; Purpose : Minimal on-chain arbitration engine
;; ============================================================

;; -------------------------
;; ERRORS
;; -------------------------
(define-constant ERR-NOT-JUROR        (err u10002))
(define-constant ERR-DISPUTE-NOT-FOUND (err u10003))
(define-constant ERR-ALREADY-VOTED    (err u10004))
(define-constant ERR-ALREADY-RESOLVED (err u10005))

;; -------------------------
;; DATA
;; -------------------------

(define-data-var dispute-counter uint u0)

;; dispute-id => dispute data
(define-map disputes
  { id: uint }
  {
    creator: principal,
    resolved: bool,
    votes-for: uint,
    votes-against: uint
  }
)

;; dispute-id + juror => voted?
(define-map votes
  { id: uint, juror: principal }
  { voted: bool }
)

;; approved jurors
(define-map jurors
  { juror: principal }
  { active: bool }
)

;; -------------------------
;; JUROR MANAGEMENT
;; -------------------------

(define-public (add-juror (juror principal))
  (begin
    (asserts! (is-some (some juror)) (ok false))
    (map-set jurors { juror: juror } { active: true })
    (ok true)
  )
)

(define-public (remove-juror (juror principal))
  (begin
    (asserts! (is-some (some juror)) (ok false))
    (map-delete jurors { juror: juror })
    (ok true)
  )
)

;; -------------------------
;; DISPUTE CREATION
;; -------------------------

(define-public (open-dispute)
  (let ((id (+ (var-get dispute-counter) u1)))
    (begin
      (var-set dispute-counter id)
      (map-set disputes
        { id: id }
        {
          creator: tx-sender,
          resolved: false,
          votes-for: u0,
          votes-against: u0
        }
      )
      (ok id)
    )
  )
)

;; -------------------------
;; VOTING
;; -------------------------

(define-public (vote
  (id uint)
  (support bool)
)
  (let ((dispute (map-get? disputes { id: id })))
    (begin
      (asserts! (is-some (some id)) (ok false))
      (asserts! (is-some dispute) ERR-DISPUTE-NOT-FOUND)
      (asserts!
        (is-some (map-get? jurors { juror: tx-sender }))
        ERR-NOT-JUROR
      )
      (asserts!
        (is-none (map-get? votes { id: id, juror: tx-sender }))
        ERR-ALREADY-VOTED
      )
      (asserts!
        (not (get resolved (unwrap! dispute ERR-DISPUTE-NOT-FOUND)))
        ERR-ALREADY-RESOLVED
      )

      (map-set votes
        { id: id, juror: tx-sender }
        { voted: true }
      )

      (if support
        (map-set disputes
          { id: id }
          (merge (unwrap! dispute ERR-DISPUTE-NOT-FOUND)
            { votes-for: (+ (get votes-for (unwrap! dispute ERR-DISPUTE-NOT-FOUND)) u1) }
          )
        )
        (map-set disputes
          { id: id }
          (merge (unwrap! dispute ERR-DISPUTE-NOT-FOUND)
            { votes-against: (+ (get votes-against (unwrap! dispute ERR-DISPUTE-NOT-FOUND)) u1) }
          )
        )
      )

      (ok support)
    )
  )
)

;; -------------------------
;; FINALIZATION
;; -------------------------

(define-public (finalize (id uint))
  (let ((dispute (map-get? disputes { id: id })))
    (begin
      (asserts! (is-some (some id)) (ok false))
      (asserts! (is-some dispute) ERR-DISPUTE-NOT-FOUND)
      (asserts!
        (not (get resolved (unwrap! dispute ERR-DISPUTE-NOT-FOUND)))
        ERR-ALREADY-RESOLVED
      )

      (map-set disputes
        { id: id }
        (merge (unwrap! dispute ERR-DISPUTE-NOT-FOUND)
          { resolved: true }
        )
      )

      (ok
        (>=
          (get votes-for (unwrap! dispute ERR-DISPUTE-NOT-FOUND))
          (get votes-against (unwrap! dispute ERR-DISPUTE-NOT-FOUND))
        )
      )
    )
  )
)

;; -------------------------
;; READ-ONLY VIEWS
;; -------------------------

(define-read-only (get-dispute (id uint))
  (map-get? disputes { id: id })
)

(define-read-only (is-juror (juror principal))
  (is-some (map-get? jurors { juror: juror }))
)
