package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

func main() {
	file, err := os.Open("file.txt")
	logErrorIfExists(err)

	// remember to close the file at the end of the program
	defer file.Close()

	// read the file line by line using scanner
	scanner := bufio.NewScanner(file)

	fails := findAsyncTestsWithoutDone(scanner)

	fmt.Printf("failed tests: %s", fails)

	err = scanner.Err()
	logErrorIfExists(err)
}

func logErrorIfExists(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func findAsyncTestsWithoutDone(scanner *bufio.Scanner) []string {
	thenCount := 0
	doneCount := 0
	lit := ""
	var fails = []string{}

	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "it('") {
			fmt.Printf("line: %s\n", line)
			if len(lit) > 0 {
				if thenCount > 0 && doneCount == 0 {
					fails = append(fails, lit)
				}
			}
			lit = line
			thenCount = 0
			doneCount = 0
		}

		if strings.Contains(line, ").then(") {
			thenCount++
		}

		if strings.Contains(line, "done();") {
			doneCount++
		}
	}

	// Check the last block if there was one
	if len(lit) > 0 {
		if thenCount > 0 && doneCount == 0 {
			fails = append(fails, lit)
		}
	}

	return fails
}
