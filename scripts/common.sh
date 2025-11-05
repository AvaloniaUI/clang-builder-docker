B_TARGETS=(aarch64-linux-gnu x86_64-linux-gnu)


run_targets() {
  local target="$1"
  if [ -z "$target" ]; then
    for t in "${B_TARGETS[@]}"; do
      run_script "$t"
    done
  else
    run_script "$target"
  fi
}
