## Encountered Issues
- Potential for 'ACK starvation' if duplicates are silently ignored without sending an acknowledgment.
- Risk of data loss if ACK is sent before data is persisted/marked as processed.
