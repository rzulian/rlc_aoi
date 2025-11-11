cls<T> EnumRange:
  fun get(Int x) -> T:
    let to_return : T
    if to_return is Enum:
      from_int(to_return, x)
    return to_return

  fun size() -> Int:
    let to_return : T
    if to_return is Enum:
      return max(to_return) + 1
    return 0

fun<Enum T> range(T t) -> EnumRange<T>:
  let to_return : EnumRange<T>
  return to_return
