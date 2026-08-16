# Identity and Library Domains

Identity uses the real Panor registration contract (`username`, `email`, `password`) and login contract (`username`, `password`), then stores only the JWT and minimal user identity. Library never treats authentication failure as an empty collection. Visibility and deletion require ownership and refresh from the server after mutation.
