;; Transaction Monitoring Contract
;; Analyzes payment patterns and stores transaction data

(define-data-var admin principal tx-sender)

;; Map to store transactions
(define-map transactions
  { tx-id: (string-ascii 64) }
  {
    sender: principal,
    recipient: principal,
    amount: uint,
    timestamp: uint,
    institution-id: (string-ascii 64),
    category: (string-ascii 20)
  }
)

;; Map to track transaction counts by user
(define-map user-transaction-counts
  { user: principal }
  {
    total-count: uint,
    total-amount: uint,
    last-transaction-time: uint
  }
)

;; Public function to record a new transaction
(define-public (record-transaction
    (tx-id (string-ascii 64))
    (recipient principal)
    (amount uint)
    (institution-id (string-ascii 64))
    (category (string-ascii 20)))
  (let
    (
      (sender tx-sender)
      (current-time block-height)
      (user-stats (default-to
                    { total-count: u0, total-amount: u0, last-transaction-time: u0 }
                    (map-get? user-transaction-counts { user: sender })))
    )
    (asserts! (is-none (map-get? transactions { tx-id: tx-id })) (err u100))

    ;; Update user transaction counts
    (map-set user-transaction-counts
      { user: sender }
      {
        total-count: (+ (get total-count user-stats) u1),
        total-amount: (+ (get total-amount user-stats) amount),
        last-transaction-time: current-time
      }
    )

    ;; Record the transaction
    (ok (map-set transactions
      { tx-id: tx-id }
      {
        sender: sender,
        recipient: recipient,
        amount: amount,
        timestamp: current-time,
        institution-id: institution-id,
        category: category
      }
    ))
  )
)

;; Read-only function to get transaction details
(define-read-only (get-transaction (tx-id (string-ascii 64)))
  (map-get? transactions { tx-id: tx-id })
)

;; Read-only function to get user transaction statistics
(define-read-only (get-user-stats (user principal))
  (default-to
    { total-count: u0, total-amount: u0, last-transaction-time: u0 }
    (map-get? user-transaction-counts { user: user })
  )
)
