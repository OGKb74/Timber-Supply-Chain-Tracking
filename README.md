# Timber Supply Chain Tracking

A blockchain-based timber supply chain tracking system that ensures transparency and sustainability verification from forest to consumer.

## Features

- Create timber batches with origin and sustainability information
- Track ownership transfers throughout the supply chain
- Update batch status (harvested, processed, shipped, delivered)
- Maintain complete audit trail of all transactions
- Verify sustainability certifications

## Contract Functions

### Public Functions

- `create-timber-batch(origin-forest, volume, sustainability-certified, location)` - Create new timber batch
- `transfer-batch(batch-id, new-owner, new-location)` - Transfer batch ownership
- `update-batch-status(batch-id, new-status, location)` - Update batch processing status

### Read-Only Functions

- `get-batch-info(batch-id)` - Get current batch information
- `get-batch-history(batch-id, sequence)` - Get historical transaction data
- `get-total-batches()` - Get total number of batches

## Status Codes

- 1: Harvested
- 2: Processed
- 3: Shipped
- 4: Delivered

## Usage

1. Deploy contract
2. Create timber batches with `create-timber-batch`
3. Transfer ownership with `transfer-batch`
4. Update status as timber moves through supply chain

## Testing

\`\`\`bash
clarinet test
\`\`\`

## License

MIT License
\`\`\`