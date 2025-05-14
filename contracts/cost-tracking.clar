;; Cost Tracking Contract
;; Records healthcare expenditures

(define-data-var contract-owner principal tx-sender)

;; Cost records by provider and period
(define-map provider-costs
  {
    provider-id: (string-utf8 36),
    period: uint
  }
  {
    total-cost: uint,
    patient-count: uint,
    last-updated: uint
  }
)

;; Cost records by patient
(define-map patient-costs
  {
    patient-id: (string-utf8 36),
    period: uint
  }
  {
    total-cost: uint,
    service-count: uint,
    last-updated: uint
  }
)

;; Service cost records
(define-map service-costs
  {
    service-id: (string-utf8 36)
  }
  {
    provider-id: (string-utf8 36),
    patient-id: (string-utf8 36),
    service-type: (string-utf8 50),
    cost: uint,
    service-date: uint,
    period: uint
  }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Record a healthcare service cost
(define-public (record-service-cost
    (service-id (string-utf8 36))
    (provider-id (string-utf8 36))
    (patient-id (string-utf8 36))
    (service-type (string-utf8 50))
    (cost uint)
    (service-date uint)
    (period uint)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))

    ;; Record the service
    (map-set service-costs
      { service-id: service-id }
      {
        provider-id: provider-id,
        patient-id: patient-id,
        service-type: service-type,
        cost: cost,
        service-date: service-date,
        period: period
      }
    )

    ;; Update provider costs
    (match (map-get? provider-costs { provider-id: provider-id, period: period })
      existing-data
        (map-set provider-costs
          { provider-id: provider-id, period: period }
          {
            total-cost: (+ (get total-cost existing-data) cost),
            patient-count: (get patient-count existing-data),
            last-updated: block-height
          }
        )
      (map-set provider-costs
        { provider-id: provider-id, period: period }
        {
          total-cost: cost,
          patient-count: u1,
          last-updated: block-height
        }
      )
    )

    ;; Update patient costs
    (match (map-get? patient-costs { patient-id: patient-id, period: period })
      existing-data
        (map-set patient-costs
          { patient-id: patient-id, period: period }
          {
            total-cost: (+ (get total-cost existing-data) cost),
            service-count: (+ (get service-count existing-data) u1),
            last-updated: block-height
          }
        )
      (map-set patient-costs
        { patient-id: patient-id, period: period }
        {
          total-cost: cost,
          service-count: u1,
          last-updated: block-height
        }
      )
    )

    (ok true)
  )
)

;; Get provider costs for a period
(define-read-only (get-provider-costs
    (provider-id (string-utf8 36))
    (period uint)
  )
  (map-get? provider-costs { provider-id: provider-id, period: period })
)

;; Get patient costs for a period
(define-read-only (get-patient-costs
    (patient-id (string-utf8 36))
    (period uint)
  )
  (map-get? patient-costs { patient-id: patient-id, period: period })
)

;; Get service details
(define-read-only (get-service-details (service-id (string-utf8 36)))
  (map-get? service-costs { service-id: service-id })
)

;; Calculate per-patient average cost for a provider
(define-read-only (calculate-per-patient-cost
    (provider-id (string-utf8 36))
    (period uint)
  )
  (match (map-get? provider-costs { provider-id: provider-id, period: period })
    cost-data
      (let
        (
          (total-cost (get total-cost cost-data))
          (patient-count (get patient-count cost-data))
        )
        (if (> patient-count u0)
          (/ total-cost patient-count)
          u0
        )
      )
    u0
  )
)
