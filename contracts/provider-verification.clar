;; Provider Verification Contract
;; Validates healthcare entities and stores their credentials

(define-data-var contract-owner principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: (string-utf8 36) }
  {
    principal: principal,
    name: (string-utf8 100),
    specialty: (string-utf8 50),
    license-number: (string-utf8 20),
    status: uint,
    verification-date: uint
  }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Register a new provider
(define-public (register-provider
    (provider-id (string-utf8 36))
    (name (string-utf8 100))
    (specialty (string-utf8 50))
    (license-number (string-utf8 20))
  )
  (begin
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) (err u2))
    (map-set providers
      { provider-id: provider-id }
      {
        principal: tx-sender,
        name: name,
        specialty: specialty,
        license-number: license-number,
        status: u0,
        verification-date: u0
      }
    )
    (ok true)
  )
)

;; Verify a provider (only contract owner can verify)
(define-public (verify-provider (provider-id (string-utf8 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (match (map-get? providers { provider-id: provider-id })
      provider-data (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u3)
    )
  )
)

;; Suspend a provider
(define-public (suspend-provider (provider-id (string-utf8 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (match (map-get? providers { provider-id: provider-id })
      provider-data (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: u2 })
        )
        (ok true)
      )
      (err u3)
    )
  )
)

;; Read-only function to get provider details
(define-read-only (get-provider (provider-id (string-utf8 36)))
  (map-get? providers { provider-id: provider-id })
)

;; Read-only function to check if provider is verified
(define-read-only (is-provider-verified (provider-id (string-utf8 36)))
  (match (map-get? providers { provider-id: provider-id })
    provider-data (is-eq (get status provider-data) u1)
    false
  )
)
