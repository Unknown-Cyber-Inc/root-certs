#!/usr/bin/env bash
# fix_osslsigncode_bundle.sh
# Fixes PEM bundle formatting for osslsigncode compatibility
set -euo pipefail

INPUT="${1}"
OUTPUT="${2}"

echo "========================================"
echo "PEM Bundle Fixer for osslsigncode"
echo "========================================"
echo
echo "Input file: $INPUT"
echo "Output file: $OUTPUT"
echo

# Diagnose the problem
echo "DIAGNOSIS:"
echo "-----------"
CONCAT_MARKERS=$(grep -c "END CERTIFICATE-----BEGIN" "$INPUT" 2>/dev/null || echo "0")
if [[ $CONCAT_MARKERS -gt 0 ]]; then
    echo "   Found $CONCAT_MARKERS concatenated END/BEGIN markers"
    echo "   This is why osslsigncode fails!"
    echo "   Example lines:"
    grep -n "END CERTIFICATE-----BEGIN" "$INPUT" | head -3 | sed 's/^/     Line /'
else
    echo "✓ No concatenated markers found"
fi

echo "2. Verifying the fix..."
FIXED_CONCAT=$(grep -c "END.*-----BEGIN" "$OUTPUT" 2>/dev/null || echo "0")
if [[ $FIXED_CONCAT -eq 0 ]]; then
    echo "   All concatenated markers have been fixed!"
else
    echo "   Still found $FIXED_CONCAT potential issues"
fi

echo
echo "STATISTICS:"
echo "-----------"
ORIG_CERTS=$(grep -c "^-----BEGIN CERTIFICATE-----" "$INPUT" || echo "0")
ORIG_CRLS=$(grep -c "^-----BEGIN X509 CRL-----" "$INPUT" || echo "0")
FIXED_CERTS=$(grep -c "^-----BEGIN CERTIFICATE-----" "$OUTPUT" || echo "0")
FIXED_CRLS=$(grep -c "^-----BEGIN X509 CRL-----" "$OUTPUT" || echo "0")

if [[ $ORIG_CERTS -ne $FIXED_CERTS ]] || [[ $ORIG_CRLS -ne $FIXED_CRLS ]]; then
    echo
    echo "   WARNING: Certificate or CRL count changed!"
    echo "   This might indicate a parsing issue."
fi

TEMP_CERT=$(mktemp)
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{print; if(/-----END CERTIFICATE-----/) exit}' "$OUTPUT" > "$TEMP_CERT"
if openssl x509 -in "$TEMP_CERT" -noout 2>/dev/null; then
    echo "First certificate parses correctly with OpenSSL"
else
    echo "First certificate failed OpenSSL parsing"
fi
rm -f "$TEMP_CERT"

TEMP_CRL=$(mktemp)
awk '/-----BEGIN X509 CRL-----/,/-----END X509 CRL-----/{print; if(/-----END X509 CRL-----/) exit}' "$OUTPUT" > "$TEMP_CRL"
if [[ -s "$TEMP_CRL" ]]; then
    if openssl crl -in "$TEMP_CRL" -noout 2>/dev/null; then
        echo "First CRL parses correctly with OpenSSL"
    else
        echo "First CRL failed OpenSSL parsing"
    fi
else
    echo "No CRLs found in output"
fi
rm -f "$TEMP_CRL"

echo
echo "========================================"
echo "DONE! Fixed bundle saved to: $OUTPUT"
echo "========================================"
