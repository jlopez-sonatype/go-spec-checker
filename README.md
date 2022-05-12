# go-spec-checker

This utility checks that specs that test async operations with promises (using then) are properly terminated with done() call

## search.sh

Script that uses `go-spec-checker.go` to find all the missing `done` calls in a project folder, the script is preconfigured to search for `*Spec.js` and `*Spec.jsx` files

### Usage

```bash
./search.sh "</path/to/fontend/src>" [search depth defaults to 30] 
```

### Notes

- The script currently can't ignore `node_modules` so try to use the `src` folder as the parameter instead
- Double quote the mmain search route to prevent globing
