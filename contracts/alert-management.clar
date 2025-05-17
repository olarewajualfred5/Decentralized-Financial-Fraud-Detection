;; Alert Management Contract
;; Handles notification of potential fraud

(define-data-var admin principal tx-sender)

;; Map to store alerts
(define-map alerts
  { alert-id: uint }
  {
    user: principal,
    risk-score: uint,
    transaction-id: (string-ascii 64),
    alert-type: (string-ascii 20),
    timestamp: uint,
    status: (string-ascii 10)
  }
)

;; Counter for alert IDs
(define-data-var alert-counter uint u0)

;; Public function to create a new alert
(define-public (create-alert
    (user principal)
    (risk-score uint)
    (transaction-id (string-ascii 64))
    (alert-type (string-ascii 20)))
  (let
    (
      (current-time block-height)
      (new-alert-id (+ (var-get alert-counter) u1))
    )

    ;; Increment alert counter
    (var-set alert-counter new-alert-id)

    ;; Create the alert
    (ok (map-set alerts
      { alert-id: new-alert-id }
      {
        user: user,
        risk-score: risk-score,
        transaction-id: transaction-id,
        alert-type: alert-type,
        timestamp: current-time,
        status: "open"
      }
    ))
  )
)

;; Public function to update alert status
(define-public (update-alert-status
    (alert-id uint)
    (new-status (string-ascii 10)))
  (begin
    (asserts! (or (is-eq tx-sender (var-get admin))
                 (is-authorized-reviewer tx-sender))
             (err u403))

    (match (map-get? alerts { alert-id: alert-id })
      alert (ok (map-set alerts
                { alert-id: alert-id }
                (merge alert { status: new-status })))
      (err u404)
    )
  )
)

;; Map to store authorized reviewers
(define-map authorized-reviewers
  { reviewer: principal }
  { authorized: bool }
)

;; Helper function to check if a principal is an authorized reviewer
(define-private (is-authorized-reviewer (reviewer principal))
  (default-to false (get authorized (map-get? authorized-reviewers { reviewer: reviewer })))
)

;; Public function to add an authorized reviewer (admin only)
(define-public (add-reviewer (reviewer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set authorized-reviewers
      { reviewer: reviewer }
      { authorized: true }
    ))
  )
)

;; Read-only function to get alert details
(define-read-only (get-alert (alert-id uint))
  (map-get? alerts { alert-id: alert-id })
)
