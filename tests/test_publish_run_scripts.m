function test_suite = test_publish_run_scripts()
% smoke tests for publish_run_scripts (using dry-run);
% currently no files are actually generated by this test function
    initTestSuite;

function test_publish_run_scripts_dry_run_all_files()
    names_to_publish=helper_find_files(false);
    helper_run_publish_run_scripts(names_to_publish,'');

function test_publish_run_scripts_dry_run_single_file()
    names_to_publish=helper_find_files(true);
    assert(numel(names_to_publish)==1);
    fn=regexprep(names_to_publish{1},'\.m$','');
    extra_args_str=sprintf(',''%s''',fn);
    helper_run_publish_run_scripts(names_to_publish,extra_args_str);


function names_to_publish=helper_find_files(only_single_file)
    if ~has_evalc()
        cosmo_notify_test_skipped('No support for ''evalc''');
        return;
    end

    cosmomvpa_rootdir=fileparts(fileparts(mfilename('fullpath')));
    example_dir=fullfile(cosmomvpa_rootdir,'examples');

    to_publish_runs=dir(fullfile(example_dir,'run_*.m'));
    to_publish_demos=dir(fullfile(example_dir,'demo_*.m'));

    to_publish_all=cat(1,to_publish_runs,to_publish_demos);

    names_to_publish={to_publish_all.name};
    if only_single_file
        rp=randperm(numel(names_to_publish));
        names_to_publish=names_to_publish(rp(1));
    end


function helper_run_publish_run_scripts(names_to_publish,extra_args_str)
    assertTrue(numel(names_to_publish)>0,'example directory not found');

    expr=sprintf('cosmo_publish_run_scripts(''-dry''%s);',extra_args_str);
    s=evalc(expr);

    lines=cosmo_strsplit(s,'\n');
    n_lines=numel(lines);
    files_processed=cell(n_lines,1);

    for k=1:n_lines
        sp=cosmo_strsplit(lines{k},':');
        if numel(sp)==2
            fn_without_whitespace=regexprep(sp{2},'\s*','');
            mfile_fn=regexprep(fn_without_whitespace,'\.html$','.m');

            files_processed{k}=mfile_fn;
        end
    end

    files_processed_msk=~cellfun(@isempty,files_processed);
    files_processed=files_processed(files_processed_msk);

    assert(all(cosmo_match(names_to_publish,files_processed)));


function tf=has_evalc()
    tf=exist('evalc','builtin') || ~isempty(which('evalc'));