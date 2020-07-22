packer build -on-error=ask -force mincvm.json 2>&1  | tee buildlog.log
