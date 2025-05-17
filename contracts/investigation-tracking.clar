;; Investigation Tracking Contract
;; Records review and resolution of fraud cases

(define-data-var admin principal tx-sender)

;; Map to store investigations
(define-map investigations
  { case-id: uint }
  {
    alert-id: uint,
    investigator: principal,
    start-time: uint,
    last-updated: uint,
    status: (string-ascii 20),
    findings: (string-ascii 256),
    resolution: (string-ascii 20)
  }
)

;; Counter for case IDs
(define-data-var case-counter uint u0)

;; Public function to open a new investigation
(define-public (open-investigation (alert-id uint))
  (let
    (
      (current-time block-height)
      (new-case-id (+ (var-get case-counter) u1))
    )
    (asserts! (is-authorized-investigator tx-sender) (err u403))

    ;; Increment case counter
    (var-set case-counter new-case-id)

    ;; Create the investigation
    (ok (map-set investigations
      { case-id: new-case-id }
      {
        alert-id: alert-id,
        investigator: tx-sender,
        start-time: current-time,
        last-updated: current-time,
        status: "open",
        findings: "",
        resolution: "pending"
      }
    ))
  )
)

;; Public function to update investigation
(define-public (update-investigation
    (case-id uint)
    (findings (string-ascii 256))
    (status (string-ascii 20)))
  (begin
    (asserts! (is-authorized-investigator tx-sender) (err u403))

    (match (map-get? investigations { case-id: case-id })
      investigation (ok (map-set investigations
                        { case-id: case-id }
                        (merge investigation {
                          findings: findings,
                          status: status,
                          last-updated: block-height
                        })))
      (err u404)
    )
  )
)

;; Public function to close investigation
(define-public (close-investigation
    (case-id uint)
    (resolution (string-ascii 20)))
  (begin
    (asserts! (is-authorized-investigator tx-sender) (err u403))

    (match (map-get? investigations { case-id: case-id })
      investigation (ok (map-set investigations
                        { case-id: case-id }
                        (merge investigation {
                          status: "closed",
                          resolution: resolution,
                          last-updated: block-height
                        })))
      (err u404)
    )
  )
)

;; Map to store authorized investigators
(define-map authorized-investigators
  { investigator: principal }
  { authorized: bool }
)

;; Helper function to check if a principal is an authorized investigator
(define-private (is-authorized-investigator (investigator principal))
  (default-to false (get authorized (map-get? authorized-investigators { investigator: investigator })))
)

;; Public function to add an authorized investigator (admin only)
(define-public (add-investigator (investigator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set authorized-investigators
      { investigator: investigator }
      { authorized: true }
    ))
  )
)

;; Read-only function to get investigation details
(define-read-only (get-investigation (case-id uint))
  (map-get? investigations { case-id: case-id })
)
