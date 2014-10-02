function f_ds=cosmo_fx(ds, f, split_by, dim)
% apply a function to unique combinations of .sa or .fa values
%
% f_ds=cosmo_fx(ds, f, split_by, dim)
%
% Inputs:
%    ds         dataset struct
%    f          function handle
%    split_by   string or cell of strings of labels of sample or feature
%               attributes
%    dim        dimension on which split is done (1=samples, 2=features)
%
% Returns:
%    f_ds       dataset struct where the samples are the result of applying
%               f to each unique combiniation of attribtues in split_by
%
% Example:
%     % ds is a dataset with several repeats of each target. Compute the
%     % average sample value for each unique target:
%     ds=cosmo_synthetic_dataset();
%     f_ds=cosmo_fx(ds, @(x)mean(x,1), 'targets');
%     cosmo_disp(f_ds.samples)
%     > [  1.21     0.598     0.439      2.61     0.503     -1.04
%     >   0.463      3.72     0.407     0.613      1.66    -0.173 ]
%     cosmo_disp(f_ds.sa)
%     > .targets
%     >   [ 1
%     >     2 ]
%     > .chunks
%     >   [ 1
%     >     1 ]
%
%     % Compute the average sample value for each unique combination
%     % of targets and chunks:
%     ds=cosmo_synthetic_dataset('nreps',4);
%     size(ds.samples)
%     > 24 6
%     f_ds=cosmo_fx(ds, @(x)mean(x,1), {'targets','chunks'});
%     size(f_ds.samples)
%     > 6 6
%
%     % Downsample MEEG data by a factor of two
%     ds=cosmo_synthetic_dataset('type','meeg','size','small');
%     size(ds.samples)
%     > 6 6
%     downsampling_factor=2;
%     ds.fa.time_downsamp=ceil(ds.fa.time/downsampling_factor);
%     %
%     % compute average for each unique combination of channel and
%     % time_downsamp
%     ds_downsamp=cosmo_fx(ds, @(x) mean(x,2), {'chan','time_downsamp'}, 2);
%     ds_downsamp=cosmo_dim_prune(ds_downsamp); % update dim attributes
%     size(ds_downsamp.samples)
%     >  6 3
%
% See also: cosmo_split, cosmo_stack
%
% NNO Jan 2014

    if nargin<3, split_by=[]; end
    if nargin<4, dim=1; end

    if ~isa(f, 'function_handle')
        error('f must be a function handle');
    end

    % store size in other dimension - it should not change
    other_dim=3-dim;
    size_other_dim=size(ds.samples,other_dim);

    % split the dataset
    ds_split=cosmo_split(ds, split_by, dim);

    nsplits=numel(ds_split);
    res=cell(nsplits,1); % allocate space for output

    for k=1:nsplits
        ds_k=ds_split{k};

        % apply f to samples
        res_k_samples=f(ds_k.samples);

        % make sure that the size in the other dimension is the same as the
        % input
        sz_k_other_dim=size(res_k_samples,other_dim);
        if sz_k_other_dim ~= size_other_dim
            error('Wrong output size %d ~= %d in dim %d for split %d',...
                       sz_k_other_dim, size_other_dim, dim, k);
        end

        % for now just repeat values from the first sample/feature
        % XXX should be more fancy, e.g. string concatenation?
        idxs=ones(1,size(res_k_samples,dim));
        res_k=cosmo_slice(ds_k,idxs,dim);

        % store sample results
        res_k.samples=res_k_samples;
        res{k}=res_k;
    end

    % join the results
    f_ds=cosmo_stack(res,dim);


