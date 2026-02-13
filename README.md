This project requires Python 3.11 to run.
  
Start the project in virtual environment.\
``` venv\Scripts\activate ```

Please install the dependencies listed in req.txt in a Python 3.11 virtual environment.\
``` pip install -r req.txt ```

To run the model:
1. Direct(No backend API server)
   - ``` py tester.py ```

2. Using backend API server
   - Run server by ``` py server.py ```
   - Run html by ``` py -m http.server 5500 ```
   - Open [http://localhost:5500/](http://localhost:5500/)
