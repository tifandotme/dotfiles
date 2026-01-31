# Get the validity dates of a domain's SSL certificate
export def dates [domain: string] {
  let address = $"($domain):443"
  ""
  | openssl s_client -servername $domain -connect $address e> /dev/null
  | openssl x509 -noout -dates
  | lines
  | parse "{key}={value}"
  | transpose -r -d
}

# Check if a certificate is valid and calculate days remaining
export def check [domain: string] {
  let dates = (cert dates $domain)
  let expiry = ($dates.notAfter | into datetime)
  let remaining = ($expiry - (date now))

  {
    domain: $domain
    expired: ($expiry < (date now))
    expiry_date: $expiry
    days_left: ($remaining / 1day | math round)
  }
}

# Get the issuer information for a domain
export def issuer [domain: string] {
  ""
  | openssl s_client -servername $domain -connect $"($domain):443" e> /dev/null
  | openssl x509 -noout -issuer
  | str replace --regex 'issuer=\s*' ''
}

# Get SHA256 and SHA1 fingerprints of a domain's certificate
export def finger [domain: string] {
  let raw = ("" | openssl s_client -servername $domain -connect $"($domain):443" e> /dev/null)

  {
    sha256: ($raw | openssl x509 -noout -fingerprint -sha256 | str replace --regex '.*Fingerprint=' '')
    sha1: ($raw | openssl x509 -noout -fingerprint -sha1 | str replace --regex '.*Fingerprint=' '')
  }
}

# Inspect a local .pem or .crt file
export def decode [path: path] {
  openssl x509 -in $path -text -noout
}
