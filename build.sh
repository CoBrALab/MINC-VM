packer build -on-error=abort -force mincvm.json 2>&1  | tee buildlog.log
