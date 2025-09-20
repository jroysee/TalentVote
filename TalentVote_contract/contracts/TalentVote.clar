
;; title: TalentVote
;; version: 1.0.0
;; summary: A creative community platform for artist selection and cultural event programming
;; description: This contract enables artists to register, events to be created, and community voting for artist selection

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-voting-closed (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-insufficient-balance (err u107))

;; data vars
(define-data-var next-artist-id uint u1)
(define-data-var next-event-id uint u1)
(define-data-var platform-fee uint u1000000) ;; 1 STX in microSTX

;; data maps
;; Artist profiles
(define-map artists
  { artist-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    bio: (string-ascii 500),
    genre: (string-ascii 30),
    portfolio-url: (string-ascii 200),
    created-at: uint,
    total-votes: uint,
    is-active: bool
  }
)

;; Events for artist selection
(define-map events
  { event-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    location: (string-ascii 100),
    event-date: uint,
    voting-end: uint,
    max-artists: uint,
    selected-artists: (list 20 uint),
    total-votes: uint,
    prize-pool: uint,
    is-active: bool
  }
)

;; Votes for artists in specific events
(define-map votes
  { voter: principal, event-id: uint, artist-id: uint }
  { vote-weight: uint, voted-at: uint }
)

;; User voting history
(define-map user-votes
  { voter: principal, event-id: uint }
  { has-voted: bool, votes-cast: uint }
)

;; Artist participation in events
(define-map artist-events
  { artist-id: uint, event-id: uint }
  { registered: bool, votes-received: uint }
)

;; public functions

;; Register a new artist
(define-public (register-artist (name (string-ascii 50)) (bio (string-ascii 500)) (genre (string-ascii 30)) (portfolio-url (string-ascii 200)))
  (let
    (
      (artist-id (var-get next-artist-id))
    )
    (try! (stx-transfer? (var-get platform-fee) tx-sender contract-owner))
    (map-set artists
      { artist-id: artist-id }
      {
        owner: tx-sender,
        name: name,
        bio: bio,
        genre: genre,
        portfolio-url: portfolio-url,
        created-at: block-height,
        total-votes: u0,
        is-active: true
      }
    )
    (var-set next-artist-id (+ artist-id u1))
    (ok artist-id)
  )
)

;; Update artist profile
(define-public (update-artist (artist-id uint) (name (string-ascii 50)) (bio (string-ascii 500)) (genre (string-ascii 30)) (portfolio-url (string-ascii 200)))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner artist)) err-unauthorized)
    (map-set artists
      { artist-id: artist-id }
      (merge artist {
        name: name,
        bio: bio,
        genre: genre,
        portfolio-url: portfolio-url
      })
    )
    (ok true)
  )
)

;; Create a new event
(define-public (create-event (title (string-ascii 100)) (description (string-ascii 500)) (location (string-ascii 100)) (event-date uint) (voting-duration uint) (max-artists uint))
  (let
    (
      (event-id (var-get next-event-id))
      (voting-end (+ block-height voting-duration))
    )
    (try! (stx-transfer? (* (var-get platform-fee) u2) tx-sender contract-owner))
    (map-set events
      { event-id: event-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        location: location,
        event-date: event-date,
        voting-end: voting-end,
        max-artists: max-artists,
        selected-artists: (list),
        total-votes: u0,
        prize-pool: u0,
        is-active: true
      }
    )
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; Artist registers for an event
(define-public (register-for-event (artist-id uint) (event-id uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-not-found))
      (event (unwrap! (map-get? events { event-id: event-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner artist)) err-unauthorized)
    (asserts! (get is-active event) err-not-found)
    (asserts! (< block-height (get voting-end event)) err-voting-closed)
    (map-set artist-events
      { artist-id: artist-id, event-id: event-id }
      { registered: true, votes-received: u0 }
    )
    (ok true)
  )
)

;; Vote for an artist in an event
(define-public (vote-for-artist (event-id uint) (artist-id uint) (vote-weight uint))
  (let
    (
      (event (unwrap! (map-get? events { event-id: event-id }) err-not-found))
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-not-found))
      (artist-event (unwrap! (map-get? artist-events { artist-id: artist-id, event-id: event-id }) err-not-found))
      (user-vote-record (default-to { has-voted: false, votes-cast: u0 } (map-get? user-votes { voter: tx-sender, event-id: event-id })))
    )
    (asserts! (get is-active event) err-not-found)
    (asserts! (< block-height (get voting-end event)) err-voting-closed)
    (asserts! (get registered artist-event) err-not-found)
    (asserts! (not (get has-voted user-vote-record)) err-already-voted)
    (asserts! (> vote-weight u0) err-invalid-input)

    ;; Record the vote
    (map-set votes
      { voter: tx-sender, event-id: event-id, artist-id: artist-id }
      { vote-weight: vote-weight, voted-at: block-height }
    )

    ;; Update user voting record
    (map-set user-votes
      { voter: tx-sender, event-id: event-id }
      { has-voted: true, votes-cast: u1 }
    )

    ;; Update artist vote count
    (map-set artist-events
      { artist-id: artist-id, event-id: event-id }
      (merge artist-event { votes-received: (+ (get votes-received artist-event) vote-weight) })
    )

    ;; Update artist total votes
    (map-set artists
      { artist-id: artist-id }
      (merge artist { total-votes: (+ (get total-votes artist) vote-weight) })
    )

    ;; Update event total votes
    (map-set events
      { event-id: event-id }
      (merge event { total-votes: (+ (get total-votes event) vote-weight) })
    )

    (ok true)
  )
)

;; Add prize money to event pool
(define-public (add-prize-pool (event-id uint) (amount uint))
  (let
    (
      (event (unwrap! (map-get? events { event-id: event-id }) err-not-found))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set events
      { event-id: event-id }
      (merge event { prize-pool: (+ (get prize-pool event) amount) })
    )
    (ok true)
  )
)

;; Close voting and finalize event (only event creator)
(define-public (finalize-event (event-id uint))
  (let
    (
      (event (unwrap! (map-get? events { event-id: event-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator event)) err-unauthorized)
    (asserts! (>= block-height (get voting-end event)) err-voting-closed)
    (map-set events
      { event-id: event-id }
      (merge event { is-active: false })
    )
    (ok true)
  )
)

;; read only functions

;; Get artist details
(define-read-only (get-artist (artist-id uint))
  (map-get? artists { artist-id: artist-id })
)

;; Get event details
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

;; Get artist registration status for event
(define-read-only (get-artist-event-status (artist-id uint) (event-id uint))
  (map-get? artist-events { artist-id: artist-id, event-id: event-id })
)

;; Get user's vote for specific artist in event
(define-read-only (get-vote (voter principal) (event-id uint) (artist-id uint))
  (map-get? votes { voter: voter, event-id: event-id, artist-id: artist-id })
)

;; Check if user has voted in an event
(define-read-only (has-user-voted (voter principal) (event-id uint))
  (default-to { has-voted: false, votes-cast: u0 } (map-get? user-votes { voter: voter, event-id: event-id }))
)

;; Get current artist ID counter
(define-read-only (get-next-artist-id)
  (var-get next-artist-id)
)

;; Get current event ID counter
(define-read-only (get-next-event-id)
  (var-get next-event-id)
)

;; Get platform fee
(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Check if voting is still open for an event
(define-read-only (is-voting-open (event-id uint))
  (match (map-get? events { event-id: event-id })
    event (and (get is-active event) (< block-height (get voting-end event)))
    false
  )
)

;; private functions

;; Update platform fee (owner only)
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

;; Deactivate artist (owner only)
(define-public (deactivate-artist (artist-id uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set artists
      { artist-id: artist-id }
      (merge artist { is-active: false })
    )
    (ok true)
  )
)
