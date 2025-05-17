;; Institution Verification Contract
;; Validates and stores approved financial entities

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions
  { institution-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    status: (string-ascii 20),
    verification-date: uint,
    verification-level: uint
  }
)

;; Public function to verify a new institution (admin only)
(define-public (verify-institution
    (institution-id (string-ascii 64))
    (name (string-ascii 100))
    (verification-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-institutions { institution-id: institution-id })) (err u100))
    (ok (map-set verified-institutions
      { institution-id: institution-id }
      {
        name: name,
        status: "active",
        verification-date: block-height,
        verification-level: verification-level
      }
    ))
  )
)

;; Public function to check if an institution is verified
(define-read-only (is-verified (institution-id (string-ascii 64)))
  (match (map-get? verified-institutions { institution-id: institution-id })
    institution (ok (is-eq (get status institution) "active"))
    (err u404)
  )
)

;; Public function to revoke verification (admin only)
(define-public (revoke-verification (institution-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? verified-institutions { institution-id: institution-id })
      institution (ok (map-set verified-institutions
                      { institution-id: institution-id }
                      (merge institution { status: "revoked" })))
      (err u404)
    )
  )
)

;; Public function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
