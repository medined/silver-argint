# Python Environment

Python is a great programming language that integrates extremely well with AWS services through the `boto3` library.

## Environment Configuration

* Create a python virtual environment called `adobo` (a random name.)

```bash
python3 -m venv adobo
```

* Add the virtual environment directory to the files that git ignores.

```bash
echo "adobo" >> .gitignore
```

* Activate the environment

```bash
source adobo/bin/activate
```

* Download the community edition of PyCharm from https://www.jetbrains.com/pycharm/ to $HOME/Downloads.

* Install PyCharm.

```bash
tar -C $HOME/bin -xf $HOME/Downloads/pycharm-community-2019.3.4.tar.gz
```

* Create a desktop application file. After this is done, you can search for PyCharm like any installed software. For example, you can add it to your favorites bar.

```bash
cat <<EOF > $HOME/.local/share/applications/pycharm.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=PyCharm
Comment=python ide
Exec=$HOME/bin/pycharm-community-2019.3.4/bin/pycharm.sh
Icon=/home/medined/bin/pycharm-community-2019.3.4/bin/pycharm.png
Terminal=false
EOF
chmod +x $HOME/.local/share/applications/pycharm.desktop
```

## Python Configuration

Make sure you are in the python virtual environment.

* Install boto3 package to interact with AWS services.

```bash
pip install boto3
```

* Install `wheel` to help build wheels.

```bash
pip install wheel
```

* Install `python-env` to read environment files (i.e. configuration files).

```bash
pip install python-env
```
