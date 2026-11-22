# Chandak Press 360 — Wallet Backend Plan

## Final business rules
- Every agent has one wallet, maintained in integer paise.
- Admin assigns a discount percentage per agent (0–10%).
- Recharge starts as a pending request. UPI QR / bank transfer details and UTR are submitted by the agent; wallet credit happens only after an authorized admin verifies receipt.
- Agent order price is calculated from the authoritative product/rate master on the server, never from a browser-supplied amount.
- Server applies the agent's current discount, then atomically checks and debits the wallet and creates the order.
- Insufficient balance means no order and no debit.
- Every debit, credit, refund, and adjustment creates an immutable ledger row.
- Idempotency keys prevent duplicate orders/recharges if a user taps twice or retries after a network timeout.
- Refunds are explicit ledger credits; no direct wallet balance editing from the agent UI.

## D1 schema
The initial schema is in `migrations/0001_wallet.sql`. Currency values are integer paise, not floating-point rupees.

## Important implementation boundary
This schema is only the database foundation. It does **not** yet activate wallet operations or make the current Firebase app wallet-secure. Do not connect the existing client to direct D1 writes and do not deploy a UI that trusts client-supplied amounts.

Before enabling live wallet deductions, implement and test a Cloudflare Worker that:
1. Verifies Firebase ID tokens (issuer, audience, signature, expiry).
2. Resolves active user role and agent identity from a trusted source.
3. Reads the authoritative product/rate data and computes the formula server-side.
4. Applies the agent discount from an admin-only record.
5. Uses a single D1 batch/transaction for balance check, wallet debit, ledger insert, and order insert.
6. Uses unique idempotency keys and rejects replay/duplicate submissions.
7. Allows recharge credit only after admin verification; agent requests never credit their own wallet.
8. Restricts all admin operations and validates every input.

## Existing Firebase app
The current app stores products and orders in Firestore and has an older payment-clearance screen. Those paths must be migrated or deliberately bridged before production. The current browser-side formula preview is for display only and must never be treated as the amount authority.

## Deployment
No Cloudflare account IDs, D1 database IDs, Worker secrets, QR image, UPI ID, or bank details are embedded here. Those must be configured in the Cloudflare dashboard after the Worker code is reviewed. Keep all private keys and service credentials out of GitHub and browser code.
