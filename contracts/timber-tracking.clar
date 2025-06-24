;; Timber Supply Chain Tracking Contract
;; Tracks timber from forest to consumer with sustainability verification

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-invalid-volume (err u104))
(define-constant err-empty-string (err u105))
(define-constant err-invalid-batch-id (err u106))

;; Status constants for better readability
(define-constant status-harvested u1)
(define-constant status-processed u2)
(define-constant status-shipped u3)
(define-constant status-delivered u4)

(define-map timber-batches
  { batch-id: uint }
  {
    origin-forest: (string-ascii 50),
    harvest-timestamp: uint,
    volume: uint,
    current-owner: principal,
    sustainability-certified: bool,
    current-status: uint,
    location: (string-ascii 50)
  }
)

(define-map batch-history
  { batch-id: uint, sequence: uint }
  {
    timestamp: uint,
    from-owner: principal,
    to-owner: principal,
    status: uint,
    location: (string-ascii 50)
  }
)

(define-data-var next-batch-id uint u1)
(define-data-var batch-counter uint u0)

;; Input validation helpers
(define-private (is-valid-string (input (string-ascii 50)))
  (> (len input) u0)
)

(define-private (is-valid-volume (volume uint))
  (> volume u0)
)

(define-private (is-valid-status (status uint))
  (and (>= status status-harvested) (<= status status-delivered))
)

(define-private (is-valid-batch-id (batch-id uint))
  (and (> batch-id u0) (< batch-id (var-get next-batch-id)))
)

(define-private (is-valid-principal (user principal))
  (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (validate-sustainability-flag (certified bool))
  (if certified true false)
)

;; Get current timestamp (using burn-block-height as alternative to block-height)
(define-private (get-current-timestamp)
  burn-block-height
)

;; Create a new timber batch with input validation
(define-public (create-timber-batch 
  (origin-forest (string-ascii 50)) 
  (volume uint) 
  (sustainability-certified bool)
  (location (string-ascii 50))
)
  (let ((batch-id (var-get next-batch-id))
        (current-time (get-current-timestamp))
        (cert-flag (if (is-eq sustainability-certified true) true false)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-string origin-forest) err-empty-string)
    (asserts! (is-valid-volume volume) err-invalid-volume)
    (asserts! (is-valid-string location) err-empty-string)

    (map-set timber-batches
      { batch-id: batch-id }
      {
        origin-forest: origin-forest,
        harvest-timestamp: current-time,
        volume: volume,
        current-owner: tx-sender,
        sustainability-certified: cert-flag,
        current-status: status-harvested,
        location: location
      }
    )

    (map-set batch-history
      { batch-id: batch-id, sequence: u1 }
      {
        timestamp: current-time,
        from-owner: tx-sender,
        to-owner: tx-sender,
        status: status-harvested,
        location: location
      }
    )

    (var-set next-batch-id (+ batch-id u1))
    (var-set batch-counter (+ (var-get batch-counter) u1))
    (ok batch-id)
  )
)

;; Transfer batch ownership with validation
(define-public (transfer-batch (batch-id uint) (new-owner principal) (new-location (string-ascii 50)))
  (let (
    (batch (unwrap! (map-get? timber-batches { batch-id: batch-id }) err-not-found))
    (current-time (get-current-timestamp))
    (history-sequence (+ (get-last-sequence batch-id) u1))
    (validated-owner new-owner)
  )
    (asserts! (is-valid-batch-id batch-id) err-invalid-batch-id)
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    (asserts! (is-valid-string new-location) err-empty-string)
    (asserts! (is-valid-principal validated-owner) err-unauthorized)

    (map-set timber-batches
      { batch-id: batch-id }
      (merge batch { 
        current-owner: validated-owner,
        location: new-location
      })
    )

    (map-set batch-history
      { batch-id: batch-id, sequence: history-sequence }
      {
        timestamp: current-time,
        from-owner: tx-sender,
        to-owner: validated-owner,
        status: (get current-status batch),
        location: new-location
      }
    )
    (ok true)
  )
)

;; Update batch status with validation
(define-public (update-batch-status (batch-id uint) (new-status uint) (location (string-ascii 50)))
  (let (
    (batch (unwrap! (map-get? timber-batches { batch-id: batch-id }) err-not-found))
    (current-time (get-current-timestamp))
    (history-sequence (+ (get-last-sequence batch-id) u1))
  )
    (asserts! (is-valid-batch-id batch-id) err-invalid-batch-id)
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    (asserts! (is-valid-status new-status) err-invalid-status)
    (asserts! (is-valid-string location) err-empty-string)

    (map-set timber-batches
      { batch-id: batch-id }
      (merge batch { 
        current-status: new-status,
        location: location
      })
    )

    (map-set batch-history
      { batch-id: batch-id, sequence: history-sequence }
      {
        timestamp: current-time,
        from-owner: tx-sender,
        to-owner: tx-sender,
        status: new-status,
        location: location
      }
    )
    (ok true)
  )
)

;; Helper function to get the last sequence number for a batch
(define-private (get-last-sequence (batch-id uint))
  (let ((counter u1))
    (fold find-last-sequence (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) counter)
  )
)

(define-private (find-last-sequence (sequence uint) (last-found uint))
  (if (is-some (map-get? batch-history { batch-id: u1, sequence: sequence }))
    sequence
    last-found
  )
)

;; Read-only functions for querying data
(define-read-only (get-batch-info (batch-id uint))
  (if (is-valid-batch-id batch-id)
    (map-get? timber-batches { batch-id: batch-id })
    none
  )
)

(define-read-only (get-batch-history (batch-id uint) (sequence uint))
  (if (and (is-valid-batch-id batch-id) (> sequence u0))
    (map-get? batch-history { batch-id: batch-id, sequence: sequence })
    none
  )
)

(define-read-only (get-total-batches)
  (var-get batch-counter)
)

(define-read-only (is-batch-sustainable (batch-id uint))
  (if (is-valid-batch-id batch-id)
    (match (map-get? timber-batches { batch-id: batch-id })
      batch (get sustainability-certified batch)
      false
    )
    false
  )
)

(define-read-only (get-current-owner (batch-id uint))
  (if (is-valid-batch-id batch-id)
    (match (map-get? timber-batches { batch-id: batch-id })
      batch (some (get current-owner batch))
      none
    )
    none
  )
)

(define-read-only (get-batch-status (batch-id uint))
  (if (is-valid-batch-id batch-id)
    (match (map-get? timber-batches { batch-id: batch-id })
      batch (some (get current-status batch))
      none
    )
    none
  )
)

(define-read-only (get-batch-location (batch-id uint))
  (if (is-valid-batch-id batch-id)
    (match (map-get? timber-batches { batch-id: batch-id })
      batch (some (get location batch))
      none
    )
    none
  )
)

;; Check if user is authorized to modify a batch
(define-read-only (is-authorized-for-batch (batch-id uint) (user principal))
  (if (is-valid-batch-id batch-id)
    (match (map-get? timber-batches { batch-id: batch-id })
      batch (is-eq user (get current-owner batch))
      false
    )
    false
  )
)