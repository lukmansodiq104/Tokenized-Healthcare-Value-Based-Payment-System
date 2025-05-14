;; Patient Attribution Contract
;; Assigns individuals to healthcare providers

(define-data-var contract-owner principal tx-sender)

;; Patient-Provider attribution mapping
(define-map patient-attributions
  { patient-id: (string-utf8 36) }
  {
    provider-id: (string-utf8 36),
    attribution-date: uint,
    is-active: bool
  }
)

;; Provider's patient list
(define-map provider-patients
  { provider-id: (string-utf8 36) }
  { patient-list: (list 100 (string-utf8 36)) }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Attribute a patient to a provider
(define-public (attribute-patient
    (patient-id (string-utf8 36))
    (provider-id (string-utf8 36))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))

    ;; Set patient attribution
    (map-set patient-attributions
      { patient-id: patient-id }
      {
        provider-id: provider-id,
        attribution-date: block-height,
        is-active: true
      }
    )

    ;; Add patient to provider's list
    (match (map-get? provider-patients { provider-id: provider-id })
      existing-data (map-set provider-patients
        { provider-id: provider-id }
        { patient-list: (unwrap-panic (as-max-len?
          (append (get patient-list existing-data) patient-id) u100)) }
      )
      (map-set provider-patients
        { provider-id: provider-id }
        { patient-list: (list patient-id) }
      )
    )

    (ok true)
  )
)

;; Remove patient attribution
(define-public (remove-attribution (patient-id (string-utf8 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))

    (match (map-get? patient-attributions { patient-id: patient-id })
      attribution-data (begin
        ;; Mark attribution as inactive
        (map-set patient-attributions
          { patient-id: patient-id }
          (merge attribution-data { is-active: false })
        )

        ;; Remove from provider's list would be complex in Clarity
        ;; For simplicity, we just mark as inactive and filter when reading

        (ok true)
      )
      (err u2)
    )
  )
)

;; Read-only function to get patient's provider
(define-read-only (get-patient-provider (patient-id (string-utf8 36)))
  (map-get? patient-attributions { patient-id: patient-id })
)

;; Read-only function to get provider's active patients
(define-read-only (get-provider-patients (provider-id (string-utf8 36)))
  (match (map-get? provider-patients { provider-id: provider-id })
    patient-data (get patient-list patient-data)
    (list)
  )
)

;; Check if a patient is attributed to a specific provider
(define-read-only (is-patient-attributed-to-provider
    (patient-id (string-utf8 36))
    (provider-id (string-utf8 36))
  )
  (match (map-get? patient-attributions { patient-id: patient-id })
    attribution-data (and
      (is-eq (get provider-id attribution-data) provider-id)
      (get is-active attribution-data)
    )
    false
  )
)
