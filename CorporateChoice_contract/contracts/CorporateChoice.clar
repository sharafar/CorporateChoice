
;; title: CorporateChoice
;; version: 1.0.0
;; summary: A blockchain platform for takeover bids and strategic partnership approvals
;; description: This contract manages corporate takeover bids, strategic partnerships,
;;              and voting mechanisms for corporate governance decisions.

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-COMPANY-NOT-FOUND (err u101))
(define-constant ERR-COMPANY-EXISTS (err u102))
(define-constant ERR-BID-NOT-FOUND (err u103))
(define-constant ERR-BID-EXISTS (err u104))
(define-constant ERR-BID-EXPIRED (err u105))
(define-constant ERR-BID-NOT-ACTIVE (err u106))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u107))
(define-constant ERR-ALREADY-VOTED (err u108))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u109))
(define-constant ERR-PROPOSAL-EXPIRED (err u110))
(define-constant ERR-INVALID-PERCENTAGE (err u111))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Company structure
(define-map companies
  { company-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    market-cap: uint,
    shares-outstanding: uint,
    is-public: bool,
    created-at: uint
  }
)

;; Takeover bids
(define-map takeover-bids
  { bid-id: uint }
  {
    bidder: principal,
    target-company: uint,
    offer-amount: uint,
    price-per-share: uint,
    bid-type: (string-ascii 20), ;; "friendly" or "hostile"
    status: (string-ascii 20), ;; "active", "accepted", "rejected", "expired"
    expires-at: uint,
    created-at: uint,
    votes-for: uint,
    votes-against: uint,
    total-votes: uint
  }
)

;; Partnership proposals
(define-map partnership-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    company-a: uint,
    company-b: uint,
    proposal-type: (string-ascii 30), ;; "merger", "acquisition", "joint-venture", "strategic-alliance"
    terms: (string-ascii 200),
    status: (string-ascii 20), ;; "pending", "approved", "rejected", "expired"
    expires-at: uint,
    created-at: uint,
    votes-for: uint,
    votes-against: uint,
    required-approval-percentage: uint
  }
)

;; Voting records for bids
(define-map bid-votes
  { bid-id: uint, voter: principal }
  { vote: bool, voting-power: uint, voted-at: uint }
)

;; Voting records for proposals
(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint, voted-at: uint }
)

;; Shareholders map
(define-map shareholders
  { company-id: uint, shareholder: principal }
  { shares: uint, voting-power: uint }
)

;; Company and proposal counters
(define-data-var next-company-id uint u1)
(define-data-var next-bid-id uint u1)
(define-data-var next-proposal-id uint u1)

;; Helper function to get current block height
(define-private (get-current-height)
  block-height
)

;; Register a new company
(define-public (register-company (name (string-ascii 50)) (market-cap uint) (shares-outstanding uint) (is-public bool))
  (let
    (
      (company-id (var-get next-company-id))
    )
    (asserts! (is-none (map-get? companies { company-id: company-id })) ERR-COMPANY-EXISTS)
    (map-set companies
      { company-id: company-id }
      {
        name: name,
        owner: tx-sender,
        market-cap: market-cap,
        shares-outstanding: shares-outstanding,
        is-public: is-public,
        created-at: (get-current-height)
      }
    )
    ;; Set the owner as initial shareholder with 100% voting power
    (map-set shareholders
      { company-id: company-id, shareholder: tx-sender }
      { shares: shares-outstanding, voting-power: u100 }
    )
    (var-set next-company-id (+ company-id u1))
    (ok company-id)
  )
)

;; Create a takeover bid
(define-public (create-takeover-bid
  (target-company uint)
  (offer-amount uint)
  (price-per-share uint)
  (bid-type (string-ascii 20))
  (duration-blocks uint)
)
  (let
    (
      (bid-id (var-get next-bid-id))
      (company-info (unwrap! (map-get? companies { company-id: target-company }) ERR-COMPANY-NOT-FOUND))
    )
    (asserts! (> offer-amount u0) ERR-INSUFFICIENT-AMOUNT)
    (asserts! (> price-per-share u0) ERR-INSUFFICIENT-AMOUNT)
    (asserts! (not (is-eq tx-sender (get owner company-info))) ERR-NOT-AUTHORIZED)

    (map-set takeover-bids
      { bid-id: bid-id }
      {
        bidder: tx-sender,
        target-company: target-company,
        offer-amount: offer-amount,
        price-per-share: price-per-share,
        bid-type: bid-type,
        status: "active",
        expires-at: (+ (get-current-height) duration-blocks),
        created-at: (get-current-height),
        votes-for: u0,
        votes-against: u0,
        total-votes: u0
      }
    )
    (var-set next-bid-id (+ bid-id u1))
    (ok bid-id)
  )
)

;; Create a partnership proposal
(define-public (create-partnership-proposal
  (company-a uint)
  (company-b uint)
  (proposal-type (string-ascii 30))
  (terms (string-ascii 200))
  (duration-blocks uint)
  (required-approval-percentage uint)
)
  (let
    (
      (proposal-id (var-get next-proposal-id))
      (company-a-info (unwrap! (map-get? companies { company-id: company-a }) ERR-COMPANY-NOT-FOUND))
      (company-b-info (unwrap! (map-get? companies { company-id: company-b }) ERR-COMPANY-NOT-FOUND))
    )
    (asserts! (not (is-eq company-a company-b)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= required-approval-percentage u1) (<= required-approval-percentage u100)) ERR-INVALID-PERCENTAGE)
    ;; Must be owner of at least one company
    (asserts! (or
      (is-eq tx-sender (get owner company-a-info))
      (is-eq tx-sender (get owner company-b-info))
    ) ERR-NOT-AUTHORIZED)

    (map-set partnership-proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        company-a: company-a,
        company-b: company-b,
        proposal-type: proposal-type,
        terms: terms,
        status: "pending",
        expires-at: (+ (get-current-height) duration-blocks),
        created-at: (get-current-height),
        votes-for: u0,
        votes-against: u0,
        required-approval-percentage: required-approval-percentage
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Vote on a takeover bid
(define-public (vote-on-bid (bid-id uint) (vote bool))
  (let
    (
      (bid-info (unwrap! (map-get? takeover-bids { bid-id: bid-id }) ERR-BID-NOT-FOUND))
      (target-company (get target-company bid-info))
      (shareholder-info (unwrap! (map-get? shareholders { company-id: target-company, shareholder: tx-sender }) ERR-NOT-AUTHORIZED))
      (voting-power (get voting-power shareholder-info))
    )
    ;; Check if bid is still active and not expired
    (asserts! (is-eq (get status bid-info) "active") ERR-BID-NOT-ACTIVE)
    (asserts! (<= (get-current-height) (get expires-at bid-info)) ERR-BID-EXPIRED)
    ;; Check if already voted
    (asserts! (is-none (map-get? bid-votes { bid-id: bid-id, voter: tx-sender })) ERR-ALREADY-VOTED)

    ;; Record vote
    (map-set bid-votes
      { bid-id: bid-id, voter: tx-sender }
      { vote: vote, voting-power: voting-power, voted-at: (get-current-height) }
    )

    ;; Update bid vote counts
    (map-set takeover-bids
      { bid-id: bid-id }
      (merge bid-info
        {
          votes-for: (if vote (+ (get votes-for bid-info) voting-power) (get votes-for bid-info)),
          votes-against: (if vote (get votes-against bid-info) (+ (get votes-against bid-info) voting-power)),
          total-votes: (+ (get total-votes bid-info) voting-power)
        }
      )
    )
    (ok true)
  )
)

;; Vote on a partnership proposal
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let
    (
      (proposal-info (unwrap! (map-get? partnership-proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (company-a (get company-a proposal-info))
      (company-b (get company-b proposal-info))
      (shareholder-a-info (map-get? shareholders { company-id: company-a, shareholder: tx-sender }))
      (shareholder-b-info (map-get? shareholders { company-id: company-b, shareholder: tx-sender }))
    )
    ;; Must be shareholder of at least one company
    (asserts! (or (is-some shareholder-a-info) (is-some shareholder-b-info)) ERR-NOT-AUTHORIZED)
    ;; Check if proposal is still active and not expired
    (asserts! (is-eq (get status proposal-info) "pending") ERR-BID-NOT-ACTIVE)
    (asserts! (<= (get-current-height) (get expires-at proposal-info)) ERR-PROPOSAL-EXPIRED)
    ;; Check if already voted
    (asserts! (is-none (map-get? proposal-votes { proposal-id: proposal-id, voter: tx-sender })) ERR-ALREADY-VOTED)

    (let
      (
        (voting-power (if (is-some shareholder-a-info)
          (get voting-power (unwrap-panic shareholder-a-info))
          (get voting-power (unwrap-panic shareholder-b-info))
        ))
      )
      ;; Record vote
      (map-set proposal-votes
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote, voting-power: voting-power, voted-at: (get-current-height) }
      )

      ;; Update proposal vote counts
      (map-set partnership-proposals
        { proposal-id: proposal-id }
        (merge proposal-info
          {
            votes-for: (if vote (+ (get votes-for proposal-info) voting-power) (get votes-for proposal-info)),
            votes-against: (if vote (get votes-against proposal-info) (+ (get votes-against proposal-info) voting-power))
          }
        )
      )
      (ok true)
    )
  )
)

;; Finalize a takeover bid (can be called by bid creator or company owner)
(define-public (finalize-bid (bid-id uint))
  (let
    (
      (bid-info (unwrap! (map-get? takeover-bids { bid-id: bid-id }) ERR-BID-NOT-FOUND))
      (company-info (unwrap! (map-get? companies { company-id: (get target-company bid-info) }) ERR-COMPANY-NOT-FOUND))
    )
    ;; Only bidder or company owner can finalize
    (asserts! (or
      (is-eq tx-sender (get bidder bid-info))
      (is-eq tx-sender (get owner company-info))
    ) ERR-NOT-AUTHORIZED)

    (let
      (
        (votes-for (get votes-for bid-info))
        (votes-against (get votes-against bid-info))
        (new-status (if (> votes-for votes-against) "accepted" "rejected"))
      )
      (map-set takeover-bids
        { bid-id: bid-id }
        (merge bid-info { status: new-status })
      )
      (ok new-status)
    )
  )
)

;; Finalize a partnership proposal
(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal-info (unwrap! (map-get? partnership-proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (company-a-info (unwrap! (map-get? companies { company-id: (get company-a proposal-info) }) ERR-COMPANY-NOT-FOUND))
      (company-b-info (unwrap! (map-get? companies { company-id: (get company-b proposal-info) }) ERR-COMPANY-NOT-FOUND))
    )
    ;; Only company owners can finalize
    (asserts! (or
      (is-eq tx-sender (get owner company-a-info))
      (is-eq tx-sender (get owner company-b-info))
    ) ERR-NOT-AUTHORIZED)

    (let
      (
        (votes-for (get votes-for proposal-info))
        (total-possible-votes u200) ;; 100% from each company
        (approval-percentage (/ (* votes-for u100) total-possible-votes))
        (required-percentage (get required-approval-percentage proposal-info))
        (new-status (if (>= approval-percentage required-percentage) "approved" "rejected"))
      )
      (map-set partnership-proposals
        { proposal-id: proposal-id }
        (merge proposal-info { status: new-status })
      )
      (ok new-status)
    )
  )
)

;; Read-only function to get company info
(define-read-only (get-company (company-id uint))
  (map-get? companies { company-id: company-id })
)

;; Read-only function to get takeover bid info
(define-read-only (get-takeover-bid (bid-id uint))
  (map-get? takeover-bids { bid-id: bid-id })
)

;; Read-only function to get partnership proposal info
(define-read-only (get-partnership-proposal (proposal-id uint))
  (map-get? partnership-proposals { proposal-id: proposal-id })
)

;; Read-only function to get shareholder info
(define-read-only (get-shareholder-info (company-id uint) (shareholder principal))
  (map-get? shareholders { company-id: company-id, shareholder: shareholder })
)

;; Read-only function to check if user voted on bid
(define-read-only (get-bid-vote (bid-id uint) (voter principal))
  (map-get? bid-votes { bid-id: bid-id, voter: voter })
)

;; Read-only function to check if user voted on proposal
(define-read-only (get-proposal-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })
)

;; Read-only function to get next IDs
(define-read-only (get-next-company-id)
  (var-get next-company-id)
)

(define-read-only (get-next-bid-id)
  (var-get next-bid-id)
)

(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

;; Admin function to update contract owner (only current owner)
(define-public (update-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)
