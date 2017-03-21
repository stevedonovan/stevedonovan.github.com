#![feature(slice_patterns)]
fn main() {
    let res: f64 = ["1.0","xx","2.0"]
        .iter().filter_map(|s| s.parse::<f64>().ok()).sum();
    println!("sum {}",res);

    let slices: Vec<&[i32]> = Vec::new();
    slices.push(&[0]);
    slices.push(&[0,1]);
    for s in slices.iter() {
        match s {
        &[_] => println!("zero"),
        &[a, b..] => println!("match! {:?} {:?}",a,b),
        _ => println!("no match!")
        }
    }

}
