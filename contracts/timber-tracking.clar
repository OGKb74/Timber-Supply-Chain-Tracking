;; Timber Supply Chain Tracking Contract
;; Tracks timber from forest to consumer with sustainability verification

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))

(define-map timber-batches
  { batch-id: uint }
  {
    origin-forest: (string-ascii 50),
    harvest-date: uint,
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
(define-data-var next-sequence uint u1)

;; Status codes: 1=harvested, 2=processed, 3=shipped, 4=delivered
(define-public (create-timber-batch 
  (origin-forest (string-ascii 50)) 
  (volume uint) 
  (sustainability-certified bool)
  (location (string-ascii 50))
)
  (let ((batch-id (var-get next-batch-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set timber-batches
      { batch-id: batch-id }
      {
        origin-forest: origin-forest,
        harvest-date: block-height,
        volume: volume,
        current-owner: tx-sender,
        sustainability-certified: sustainability-certified,
        current-status: u1,
        location: location
      }
    )
    (map-set batch-history
      { batch-id: batch-id, sequence: u1 }
      {
        timestamp: block-height,
        from-owner: tx-sender,
        to-owner: tx-sender,
        status: u1,
        location: location
      }
    )
    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

(define-public (transfer-batch (batch-id uint) (new-owner principal) (new-location (string-ascii 50)))
  (let (
    (batch (unwrap! (map-get? timber-batches { batch-id: batch-id }) err-not-found))
    (sequence (var-get next-sequence))
  )
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    
    (map-set timber-batches
      { batch-id: batch-id }
      (merge batch { 
        current-owner: new-owner,
        location: new-location
      })
    )
    
    (map-set batch-history
      { batch-id: batch-id, sequence: sequence }
      {
        timestamp: block-height,
        from-owner: tx-sender,
        to-owner: new-owner,
        status: (get current-status batch),
        location: new-location
      }
    )
    (var-set next-sequence (+ sequence u1))
    (ok true)
  )
)

(define-public (update-batch-status (batch-id uint) (new-status uint) (location (string-ascii 50)))
  (let (
    (batch (unwrap! (map-get? timber-batches { batch-id: batch-id }) err-not-found))
    (sequence (var-get next-sequence))
  )
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    (asserts! (and (>= new-status u1) (<= new-status u4)) err-invalid-status)
    
    (map-set timber-batches
      { batch-id: batch-id }
      (merge batch { 
        current-status: new-status,
        location: location
      })
    )
    
    (map-set batch-history
      { batch-id: batch-id, sequence: sequence }
      {
        timestamp: block-height,
        from-owner: tx-sender,
        to-owner: tx-sender,
        status: new-status,
        location: location
      }
    )
    (var-set next-sequence (+ sequence u1))
    (ok true)
  )
)

(define-read-only (get-batch-info (batch-id uint))
  (map-get? timber-batches { batch-id: batch-id })
)

(define-read-only (get-batch-history (batch-id uint) (sequence uint))
  (map-get? batch-history { batch-id: batch-id, sequence: sequence })
)

(define-read-only (get-total-batches)
  (- (var-get next-batch-id) u1)
)

(define-read-only (is-batch-sustainable (batch-id uint))
  (match (map-get? timber-batches { batch-id: batch-id })
    batch (get sustainability-certified batch)
    false
  )
)

(define-read-only (get-current-owner (batch-id uint))
  (match (map-get? timber-batches { batch-id: batch-id })
    batch (some (get current-owner batch))
    none
  )
)
