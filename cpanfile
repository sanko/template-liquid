requires 'perl', '5.010000';
requires 'DateTime';
requires 'DateTime::Format::Natural';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
