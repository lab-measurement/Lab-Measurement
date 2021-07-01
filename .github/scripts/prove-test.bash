printenv 
# Prevent "Please tell me who you are" errors for certain DZIL configs
git config --global user.name 'github-actions'

# check perl version
perl -V


#
# install gnuplot version specified by environment variable $gp_version
#

cd /tmp
wget https://github.com/lab-measurement/Lab-Measurement-Homepage/raw/master/gnuplot-5.2.4.tar.gz
tar -xf gnuplot-$gp_version.tar.gz
cd gnuplot-$gp_version
./configure --prefix=$HOME/local
make
make install
export PATH="$HOME/local/bin:$PATH"
gnuplot --version 
# Sometimes Alien::Gnuplot does not find the installed gnuplot
# (but problem not reproducible, see
# https://travis-ci.org/lab-measurement/Lab-Measurement/jobs/378743671
export GNUPLOT_BINARY=$HOME/local/bin/gnuplot


#
# Install Dist::Zilla and Lab::Measurement dependencies
#

cpanm -v Dist::Zilla

# Install DZIL plugins etc if needed
cd $GITHUB_WORKSPACE
ls -la

dzil authordeps --missing | grep -vP '[^\w:]' | xargs cpanm -v
dzil listdeps --missing --cpanm | grep -vP '[^\w:~"\.]' | xargs cpanm  -v
if [ $with_pdl_graphics_gnuplot -eq "1" ]; then cpanm --verbose -f PDL::Graphics::Gnuplot; fi
cpanm -v Test::Perl::Critic


#
# Run tests
#



 # "normal" tests
prove --verbose -l -s -r t

# Perl::Critic tests
prove --verbose -l -r xt/critic/

# Pod manual test
prove --verbose xt/pod-manual-coverage.t




