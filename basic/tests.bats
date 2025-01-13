#!/usr/bin/env bats

setup() {
    INDEX=$((${BATS_TEST_NUMBER} - 1))
    echo "##### setup start" >> ./bats.log
    echo "BATS_TEST_NAME:        ${BATS_TEST_NAME}" >> ./bats.log
    echo "BATS_TEST_FILENAME:    ${BATS_TEST_FILENAME}" >> ./bats.log
    echo "BATS_TEST_DIRNAME:     ${BATS_TEST_DIRNAME}" >> ./bats.log
    echo "BATS_TEST_NAMES:       ${BATS_TEST_NAMES[$INDEX]}" >> ./bats.log
    echo "BATS_TEST_DESCRIPTION: ${BATS_TEST_DESCRIPTION}" >> ./bats.log
    echo "BATS_TEST_NUMBER:      ${BATS_TEST_NUMBER}" >> ./bats.log
    echo "BATS_TMPDIR:           ${BATS_TMPDIR}" >> ./bats.log
    echo "##### setup end" >> ./bats.log
}

teardown() {
    echo -e "##### teardown ${BATS_TEST_NAME}\n" >> ./bats.log

}

@test "example status and output, lines" {
    echo "    example 1" >> ./bats.log

    run ./status.sh

    [ "$status" -eq 1 ]
    [ "${output}" = "foobar" ]
    [ "${lines[0]}" = "foobar" ]
}

@test "example skip" {
    echo "    example 2" >> ./bats.log

    skip "skipped test"
}

@test "example load" {
    echo "    example 3" >> ./bats.log

    load helper
    assert_equal 1 1
}